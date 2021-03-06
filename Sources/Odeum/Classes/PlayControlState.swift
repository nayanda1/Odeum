//
//  PlayControlState.swift
//  Odeum
//
//  Created by Nayanda Haberty on 23/01/21.
//

import Foundation
#if canImport(UIKit)
import UIKit

protocol StatedIcon {
    var icon: UIImage { get }
}

extension RawRepresentable where RawValue == String, Self: StatedIcon {
    
    var icon: UIImage {
        #if COCOAPODS
        let bundle = Bundle(for: OdeumPlayerView.self)
        return UIImage(named: rawValue, in: bundle, compatibleWith: nil)!
        #else
        return UIImage(named: rawValue, in: .module, compatibleWith: nil)!
        #endif
    }
}

public enum PlayState: String, StatedIcon {
    case played = "ic_pause"
    case paused = "ic_play"
}

public enum AudioState: String, StatedIcon {
    case mute = "ic_mute"
    case unmute = "ic_umute"
}

public enum ReplayStep: String, StatedIcon {
    case fiveSecond = "ic_5_replay"
    case tenSecond = "ic_10_replay"
    case thirtySecond = "ic_30_replay"
    
    var timeInterval: TimeInterval {
        switch self {
        case .fiveSecond:
            return 5
        case .tenSecond:
            return 10
        case .thirtySecond:
            return 30
        }
    }
}

public enum ForwardStep: String, StatedIcon {
    case fiveSecond = "ic_5_forward"
    case tenSecond = "ic_10_forward"
    case thirtySecond = "ic_30_forward"
    
    var timeInterval: TimeInterval {
        switch self {
        case .fiveSecond:
            return 5
        case .tenSecond:
            return 10
        case .thirtySecond:
            return 30
        }
    }
}

public enum FullScreenState: String, StatedIcon {
    case fullScreen = "ic_minimize"
    case minimize = "ic_fullscreen"
}
#endif
