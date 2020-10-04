//
//  newNoteTableViewCell.swift
//  topline
//
//  Created by Michael Handkins on 9/27/20.

import UIKit
import RealmSwift
import AVFoundation

class newNoteTableViewCell: UITableViewCell, UITextViewDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    let realm = try! Realm()

    @IBOutlet weak var lyricsField: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    
    var recorder = AVAudioRecorder()
    var player = AVAudioPlayer()
    var fileName: String? {
        didSet {
            audioFileURL = getDocumentDirectory().appendingPathComponent(fileName!)
        }
    }
    var audioFileURL: URL?
    
    var recordings: Results<Recording>?
    
    func loadRecordings() {
        recordings = realm.objects(Recording.self)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // make sure scroll is disabled
        lyricsField.isScrollEnabled = false
        loadRecordings()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    //MARK: - AVAudioRecorder and Player Delegate Methods
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if recordButton.currentImage == UIImage(systemName: "record.circle") {
//            recorder.record()
            recorder = AVAudioSession.sharedInstance().startRecording(for: audioFileURL!, with: self)!
            recordButton.setImage(UIImage(systemName: "record.circle.fill"), for: .normal)
        } else if recordButton.currentImage == UIImage(systemName: "record.circle.fill") {
            recorder.stop()
            recordButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        } else if recordButton.currentImage == UIImage(systemName: "play.circle") {
            setupPlayer()
            player.play()
            recordButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
        } else {
            player.stop()
            recordButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
    }
    
    func getDocumentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker])
        } catch let error as NSError {
            print(error.description)
        }
        
        let recordSettings = [AVFormatIDKey : kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 320000,
                              AVNumberOfChannelsKey : 2,
                              AVSampleRateKey : 44100.0] as [String : Any]
        
        do {
            recorder = try AVAudioRecorder(url: self.audioFileURL!, settings: recordSettings)
            recorder.delegate = self
            recorder.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        print(recorder.url.absoluteString)
        //A new Recording object is created to store the fileName and audioFileURL
        let newRecording = Recording()
        if let safeFileName = fileName {
            newRecording.audioFileName = safeFileName
//            newRecording.urlString = recorder.url.absoluteString
            //The Recording is then added to realm
            do {
                try realm.write {
                    realm.add(newRecording)
                    print("New recording added to Realm")
                }
            } catch {
                print("Error when adding new Recording to realm: \(error)")
            }
        }
    }
    
    func setupPlayer() {
        
        if let safeURL = audioFileURL {
            do {
                
                let session = AVAudioSession.sharedInstance()
                
                try session.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
                try session.setActive(true)
                
                player = try AVAudioPlayer(contentsOf: safeURL)
                print("Player set up to use the cell's audio URL")
                player.delegate = self
                player.prepareToPlay()
                player.volume = 1.0
            } catch {
                print(error)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
    }
    
}
