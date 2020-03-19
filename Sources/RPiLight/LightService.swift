/*
 RPiLight

 Copyright (c) 2018 Adam Thayer
 Licensed under the MIT license, as follows:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */

import Foundation

import ArgumentParser
import Logging
import Yams

import LED
import Service

struct LightServiceCmd: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Aquarium Light Controller for Raspberry Pi",
        subcommands: [Service.self, Preview.self],
        defaultSubcommand: Service.self)
        
    enum VerbosityMode: String, RawRepresentable, ExpressibleByArgument {
        case normal
        case verbose
        case trace
    }    
        
    struct Options: ParsableArguments {
        @Option(name: [.long, .short], default: .normal)
        var verbosity: VerbosityMode
                
        @Option(name: [.long, .short], default: "config.yml")
        var configFile: String
        
        @Option(name: [.long, .short], default: "schedule.yml")
        var scheduleFile: String
    }
    
    static func setLoggingLevel(_ level: VerbosityMode) {
        switch level {
            case .normal:
                break
            case .verbose:
                ServiceLogHandler.logLevelOverride = .debug
                break
            case .trace:
                ServiceLogHandler.logLevelOverride = .trace
                break
        }
    }
}

extension LightServiceCmd {
    struct Service: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Run the Light Service")        
        
        @OptionGroup()
        var options: LightServiceCmd.Options

        func run() {
            setLoggingLevel(options.verbosity)
            
            let service = LightService(configFile: options.configFile, scheduleFile: options.scheduleFile)
            service.run(withPreview: false)
        }
    }
}

extension LightServiceCmd {
    struct Preview: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Preview the Light Service")                

        @OptionGroup()
        var options: LightServiceCmd.Options
        
        func run() {
            setLoggingLevel(options.verbosity)            

            let service = LightService(configFile: options.configFile, scheduleFile: options.scheduleFile)
            service.run(withPreview: true)
        }
    }
}

class LightService {
    var channels: LEDChannelSet
    let configuration: ServiceDescription
    var schedule: ScheduleDescription

    init(configFile: String, scheduleFile: String) {
        let configuration = LightService.loadConfiguration(file: configFile)
        let schedule = LightService.loadSchedule(file: scheduleFile)
        let channels = LightService.createChannelSet(
            withDescriptions: configuration.controllers,
            boardType: configuration.board)

        self.configuration = configuration
        self.schedule = schedule
        self.channels = channels
    }

    func applyLoggingLevel() {
        if let loggingLevel = configuration.logLevel {
            ServiceLogHandler.logLevelOverride = Logger.Level(loggingLevel)
        }
    }

    func run(withPreview: Bool = false) {
        // Before we start running, drop root
        let originalUid = self.dropRoot()

        // Solidify Some Config Inputs
        let username: String = getUsername(uid: originalUid) ?? "Unknown"
        let gamma: Gamma = configuration.gamma ?? 1.8

        log.info("Startup User: \(username)")
        log.info("Final User: \(configuration.username)")
        log.info("Configured Board: \(configuration.board.rawValue)")
        log.info("Configured Gamma: \(gamma)")
        for controller in configuration.controllers {
            log.info("Controller \(controller.type):")
            if let address = controller.address {
                log.info("  Address: \(address)")
            }
            if let frequency = controller.frequency {
                log.info("  Frequency: \(frequency) Hz")
            }

            log.info("  Channels: ")
            for (token, index) in controller.channels {
                log.info("    \(token): Channel \(index)")
            }
        }

        //
        // MARK: Initialize Light Controller and Run
        //
        let behavior: Behavior = withPreview ? PreviewLightBehavior() : DefaultLightBehavior()

        do {
            let controller = try LightController(gamma: gamma,
                                                  channels: channels.asArray(),
                                                  withSchedule: schedule.schedule,
                                                  behavior: behavior)
            controller.setStopHandler { _ in
                if withPreview {
                    log.info("Simulation Complete")
                    exit(0)
                } else {
                    log.error("Controller unexpectedly stopped.")
                    exit(1)
                }
            }

            if let lunarCycle = schedule.lunarCycle, !withPreview {
                let lunarCycleController = LunarCycleController(schedule: lunarCycle)
                controller.setEvent(controller: lunarCycleController)
            }

            controller.start()
            dispatchMain()
        } catch {
            log.error("Unable to create Controller")
        }
    }

    private func dropRoot() -> uid_t {
        // Find target user
        let originalUid = getuid()
        let targetUsername = configuration.username
        guard let targetUid = getUid(username: targetUsername) else {
            fatalError("Cannot find user '\(targetUsername)'.")
        }

        // Remove Access Now that We Are Memory Mapped
        if targetUid != originalUid {
            guard setuid(targetUid) == 0 else {
                fatalError("Couldn't switch to user '\(targetUsername)'")
            }
        }

        return originalUid
    }

    static private func createChannelSet(
        withDescriptions descriptions: [ServiceControllerDescription],
        boardType: ServiceBoardType
    ) -> LEDChannelSet {
        let channels = LEDChannelSet()

        for controllerDescription in descriptions {
            do {
                let module = LightService.createModule(withDescription: controllerDescription, boardType: boardType)
                try channels.add(module: module)
            } catch {
                log.error("Failed to create LED Controller Modules")
                exit(-1)
            }
        }

        return channels
    }

    static private func createModule(
        withDescription configuration: ServiceControllerDescription,
        boardType: ServiceBoardType
    ) -> LEDModule {
        do {
            let moduleType = LEDModuleType(configType: configuration.type)
            let moduleBoardType = LEDBoardType(configType: boardType)

            let module = try moduleType.createModule(board: moduleBoardType, configuration: configuration)
            return module
        } catch LEDModuleError.noImplementationAvailable {
            log.error("No implementation available for: \(configuration.type)")
            exit(-1)
        } catch LEDModuleError.noHardwareAccess {
            log.error("Unable to Access Hardware for: \(configuration.type)")
            exit(-1)
        } catch LEDModuleError.invalidBoardType(let board) {
            log.error("Module \"\(configuration.type)\" Doesn't Support Board: \(board)")
            exit(-1)
        } catch LEDModuleError.missingFrequency {
            log.error("Frequency must be specified for: \(configuration.type)")
            exit(-1)
        } catch LEDModuleError.invalidFrequency(let min, let max, let actual) {
            log.error("Module \"\(configuration.type)\" expects frequency \(actual) to be between \(min) and \(max)")
            exit(-1)
        } catch {
            log.error("\(error.localizedDescription)")
            exit(-1)
        }
    }

    static private func configureChannelSet(_ channelSet: LEDChannelSet, schedule: ScheduleDescription) {
        for (token, channelSchedule) in schedule.schedule {
            guard let channel = channelSet[token] else {
                fatalError("Attempted to configure unknown channel '\(token)")
            }

            channel.minIntensity = channelSchedule.minIntensity ?? 0.0
        }
    }

    static private func loadConfiguration(file: String) -> ServiceDescription {
        do {
            return try loadDescription(ServiceDescription.self, file: file, name: "Configuration")
        } catch {
            fatalError("\(error)")
        }
    }

    static private func loadSchedule(file: String) -> ScheduleDescription {
        do {
            return try loadDescription(ScheduleDescription.self, file: file, name: "Schedule")
        } catch {
            fatalError("\(error)")
        }
    }

    static private func loadDescription<T>(_ type: T.Type, file: String, name: String) throws -> T where T: Decodable {
        let configDir = FileManager.default.currentDirectoryUrl.appendingPathComponent("config")
        let fileUrl = configDir.appendingPathComponent(file)
        log.debug("Opening \(name): \(fileUrl.absoluteString)")

        let description = try decode(type, file: fileUrl)
        return description
    }

    static private func decode<T>(_ type: T.Type, file: URL) throws -> T where T: Decodable {
        let fileExtension = file.pathExtension.lowercased()

        if fileExtension == "yaml" || fileExtension == "yml" {
            return try decodeYaml(type, file: file)
        } else if fileExtension == "json" {
            return try decodeJson(type, file: file)
        }

        log.warning("\(file.absoluteString) has unknown file extension, assuming JSON")
        return try decodeJson(type, file: file)
    }

    static private func decodeJson<T>(_ type: T.Type, file: URL) throws -> T where T: Decodable {
        let encodedJson = try Data(contentsOf: file)
        log.debug("JSON From: \(file.absoluteString)")
        log.debug("\(String(data: encodedJson, encoding: .utf8) ?? "")")
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: encodedJson)
    }

    static private func decodeYaml<T>(_ type: T.Type, file: URL) throws -> T where T: Decodable {
        let encodedYaml = try String(contentsOf: file, encoding: .utf8)
        log.debug("YAML From: \(file.absoluteString)")
        log.debug("\(encodedYaml)")

        let decoder = YAMLDecoder()
        return try decoder.decode(type, from: encodedYaml)
    }
}
