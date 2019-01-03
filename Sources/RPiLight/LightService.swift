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

class LightService {
    let configuration: ServiceConfiguration
    var module: Module
    var schedule: Schedule
    var channels: [String: Channel]

    init(configFile: String, scheduleFile: String) {
        let configuration = LightService.loadConfiguration(file: configFile)
        let schedule = LightService.loadSchedule(file: configFile)
        let module = LightService.createModule(withConfiguration: configuration)
        let channels = LightService.configureChannels(withModule: module, schedule: schedule)

        self.configuration = configuration
        self.schedule = schedule
        self.module = module
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
        Log.info("Configured PWM Module: \(configuration.type.rawValue)")
        Log.info("Configured PWM Frequency: \(configuration.frequency) Hz")
        Log.info("Configured Gamma: \(configuration.gamma)")
        for (token, channel) in channels {
            Log.info("  Channel \(token): Min Intensity = \(channel.minIntensity)")
        }

        //
        // MARK: Initialize Light Controller and Run
        //
        let behavior: Behavior = withPreview ? PreviewLightBehavior() : DefaultLightBehavior()
        let controller = try! LightController(gamma: configuration.gamma, channels: Array(channels.values), withSchedule: schedule.channels, behavior: behavior)
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

    static private func createModule(withConfiguration configuration: ServiceConfiguration) -> Module {
        do {
            let moduleType: ModuleType = .simulated
            let boardType: BoardType = BoardType.bestGuess() ?? .desktop
            let module = try moduleType.createModule(board: boardType, frequency: Int(configuration.frequency), gamma: configuration.gamma)

            return module
        } catch ModuleInitError.noHardwareAccess {
            Log.error("Unable to Access Hardware")
            exit(-1)
        } catch ModuleInitError.invalidBoardType(let board){
            Log.error("PWM Module Doesn't Support Board: \(board)")
            exit(-1)
        } catch ModuleInitError.invalidFrequency(let min, let max, let actual) {
            Log.error("PWM Module expects frequency \(actual) to be between \(min) and \(max)")
            exit(-1)
        } catch {
            Log.error(error)
            exit(-1)
        }
    }

    static private func configureChannels(withModule module: Module, schedule: Schedule) -> [String: Channel] {
        // Process Channels
        let activeChannels = module.availableChannels.map { (token : String) -> Channel in
            do {
               return try module.createChannel(with: token)
            } catch {
                Log.error("Unable to create channel \(token)")
                exit(-1)
            }
        }

        let activeChannelDict = activeChannels.reduce([String: Channel]()) { (dict, channel) -> [String: Channel] in
            var dict = dict
            dict[channel.token] = channel
            return dict
        }

        //
        // MARK: Configure Channels
        //
        for (token, channelSchedule) in schedule.channels {
            guard var channel = activeChannelDict[token] else {
                fatalError("Attempted to configure unknown channel '\(token)")
            }
    
            channel.minIntensity = channelSchedule.minIntensity
        }

        return activeChannelDict
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