//
//  TrackMerger.swift
//  AudioRecorder
//
//  Created by Clay on 5/19/17.
//  Copyright © 2017 Clay Ellis. All rights reserved.
//

import Foundation
import AVFoundation

internal class TrackMerger {
    
    enum Error: Swift.Error {
        case urlsNotUnique
        case invalidOptions
        case destinationTrackError
        case mergingTrackError
        case exportSessionError
        case failed(error: Swift.Error)
        case cancelled
    }
    
    func merge(trackAt activeURL: URL, intoTrackAt masterURL: URL, writeTo outputURL: URL? = nil, deleteMergingTrack: Bool = true, inputFileType: String = AVAssetExportPresetPassthrough, outputFileType: AVFileType = .mp4, completion: @escaping ((URL?, Error?) -> ())) {
        do {
            guard activeURL != masterURL else {
                throw Error.urlsNotUnique
            }
            let composition = AVMutableComposition()
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let masterAsset = AVURLAsset(url: masterURL)
            let activeAsset = AVURLAsset(url: activeURL)
            guard let masterTrack = masterAsset.tracks(withMediaType: AVMediaType.audio).first else {
                throw Error.destinationTrackError
            }
            guard let activeTrack = activeAsset.tracks(withMediaType: AVMediaType.audio).first else {
                throw Error.mergingTrackError
            }
            try compositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: masterAsset.duration), of: masterTrack, at: .zero)
            try compositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: activeAsset.duration), of: activeTrack, at: masterAsset.duration)
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: inputFileType) else {
                throw Error.exportSessionError
            }
            exportSession.outputFileType = outputFileType
            if let outputURL = outputURL {
                exportSession.outputURL = outputURL
            } else {
                deleteExistingFile(at: masterURL)
                exportSession.outputURL = masterURL
            }
            if deleteMergingTrack {
                deleteExistingFile(at: activeURL)
            }
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    completion(exportSession.outputURL, nil)
                case .failed:
                    let error = exportSession.error!
                    completion(nil, .failed(error: error))
                case .cancelled:
                    completion(nil, .cancelled)
                default:
                    break
                }
            }
        } catch (let error as Error) {
            completion(nil, error)
        } catch {
            completion(nil, .failed(error: error))
        }
    }
    
    private func deleteExistingFile(at url: URL) {
        let filePath = url.path
        let manager = FileManager.default
        if manager.fileExists(atPath: filePath) {
            try? manager.removeItem(atPath: filePath)
        }
    }
    
}
