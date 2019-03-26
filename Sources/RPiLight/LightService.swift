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

import Core
import Logging
import PWM

extension LEDBoardType {
    init(configType: ServiceBoardType) {
        switch configType {
        case .raspberryPi: self = .raspberryPi
        }
    }
}

extension LEDModuleType {
    init(configType: ServiceControllerType) {
        switch configType {
        case .simulated: self = .simulated
        case .pca9685: self = .pca9685
        case .raspberryPwm: self = .hardware
        case .mcp4725: self = .mcp4725
        }
    }
}

extension ServiceControllerConfiguration: LEDModuleConfig {}

extension LEDChannel: Channel {}

class LightService {
    let configuration: ServiceConfiguration
    var channels: LEDChannelSet
    var schedule: Schedule

    init(configFile: String, scheduleFile: String) {
        let configuration = LightService.loadConfiguration(file: configFile)
        let schedule = LightService.loadSchedule(file: scheduleFile)
        let channels = LightService.createChannelSet(withConfig: configuration)

        LightService.configureChannelSet(channels, schedule: schedule)

        self.configuration = configuration
        self.schedule = schedule
        self.channels = channels
    }

    func applyLoggingLevel() {
        Log.setLoggingLevel(LogLevel(configuration.logLevel))
    }

    func run(withPreview: Bool = false) {
        // Before we start running, drop root
        let originalUid = self.dropRoot()

        Log.info("Startup User: \(getUsername(uid: originalUid) ?? "Unknown")")
        Log.info("Final User: \(configuration.username)")
        Log.info("Configured Board: \(configuration.board.rawValue)")
        Log.info("Configured Gamma: \(configuration.gamma)")
        for controller in configuration.controllers {
            Log.info("Controller \(controller.type):")
            if let address = controller.address {
                Log.info("  Address: \(address)")
            }
            if let frequency = controller.frequency {
                Log.info("  Frequency: \(frequency) Hz")
            }

            Log.info("  Channels: ")
            for (token, index) in controller.channels {
                Log.info("    \(token): Channel \(index)")
            }
        }

        //
        // MARK: Initialize Light Controller and Run
        //
        let behavior: Behavior = withPreview ? PreviewLightBehavior() : DefaultLightBehavior()

        let controller = try! LightController(gamma: configuration.gamma, channels: channels.asArray(), withSchedule: schedule.channels, behavior: behavior)
        controller.setStopHandler { (controller) in
            if withPreview {
                Log.info("Simulation Complete")
                exit(0)
            } else {
                Log.error("Controller unexpectedly stopped.")
                exit(1)
            }
        }

        if let lunarCycle = schedule.lunarCycle, !withPreview {
            let lunarCycleController = LunarCycleController(schedule: lunarCycle)
            controller.setEvent(controller: lunarCycleController)
        }

        controller.start()
        dispatchMain()
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

    static private func createChannelSet(withConfig configuration: ServiceConfiguration) -> LEDChannelSet {
        let channels = LEDChannelSet()

        for controllerConfig in configuration.controllers {
            do {
                let module = LightService.createModule(withConfig: controllerConfig, boardType: configuration.board)
                try channels.add(module: module)
            } catch {
                Log.error("Unable to create modules")
                exit(-1)
            }
        }

        return channels
    }

    static private func createModule(withConfig configuration: ServiceControllerConfiguration, boardType: ServiceBoardType) -> LEDModule {
        do {
            let moduleType = LEDModuleType(configType: configuration.type)
            let moduleBoardType = LEDBoardType(configType: boardType)

            let module = try moduleType.createModule(board: moduleBoardType, configuration: configuration)
            return module
        } catch LEDModuleError.noImplementationAvailable {
            Log.error("No implementation available for: \(configuration.type)")
            exit(-1)
        } catch LEDModuleError.noHardwareAccess {
            Log.error("Unable to Access Hardware for: \(configuration.type)")
            exit(-1)
        } catch LEDModuleError.invalidBoardType(let board) {
            Log.error("Module \"\(configuration.type)\" Doesn't Support Board: \(board)")
            exit(-1)
        } catch LEDModuleError.missingFrequency {
            Log.error("Frequency must be specified for: \(configuration.type)")
            exit(-1)
        } catch LEDModuleError.invalidFrequency(let min, let max, let actual) {
            Log.error("Module \"\(configuration.type)\" expects frequency \(actual) to be between \(min) and \(max)")
            exit(-1)
        } catch {
            Log.error(error)
            exit(-1)
        }
    }

    static private func configureChannelSet(_ channelSet: LEDChannelSet, schedule: Schedule) {
        for (token, channelSchedule) in schedule.channels {
            guard let channel = channelSet[token] else {
                fatalError("Attempted to configure unknown channel '\(token)")
            }
    
            channel.minIntensity = channelSchedule.minIntensity
        }
    }

    static private func loadConfiguration(file: String) -> ServiceConfiguration {
        let configDir = FileManager.default.currentDirectoryUrl.appendingPathComponent("config")
        let configUrl = configDir.appendingPathComponent(configFile.value)
        Log.debug("Opening Configuration: \(configUrl.absoluteString)")

        do {
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(ServiceConfiguration.self, fromFile: configUrl)
        
            return configuration
        } catch {
            fatalError("\(error)")
        }
    }

    static private func loadSchedule(file: String) -> Schedule {
        let configDir = FileManager.default.currentDirectoryUrl.appendingPathComponent("config")
        let configUrl = configDir.appendingPathComponent(configFile.value)
        Log.debug("Opening Schedule: \(configUrl.absoluteString)")

        do {
            let decoder = JSONDecoder()
            let schedule = try decoder.decode(Schedule.self, fromFile: configUrl)
        
            return schedule
        } catch {
            fatalError("\(error)")
        }
    }
}
