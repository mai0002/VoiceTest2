//
//  ViewController.swift
//  VoiceTest2
//
//  Created by 稲垣麻衣 on 2018/09/16.
//  Copyright © 2018年 稲垣麻衣. All rights reserved.
//

/*
 
 音声入力機能
 参考：https://swiswiswift.com/2017/05/23/音声認識sfspeechrecognizer/
  参考サイトとの差異は以下の通り（動かなかったので）
  l107：guard let inputNode: AVAudioInputNode に書き換え
  infoplist：キー：NSMicrophoneUsageDescriptio も追加
 
 */

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    // プロパティ
    // localeのidentifierに言語を指定。日本語はja-JP,英語はen-US
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    //録音の開始、停止ボタン
    var recordButton : UIButton!
    
    @IBOutlet weak var massageResult: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("１：初期状態")
        //audioEngine.stop() // audioは最初停止状態
        
        //録音を開始するボタンの設定
        recordButton = UIButton()
        recordButton.frame = CGRect(x: 70, y: 150, width: 200, height: 40)
        recordButton.backgroundColor = UIColor.lightGray
        recordButton.addTarget(self, action: #selector(recordButtonTapped(sender:)), for:.touchUpInside)
        recordButton.setTitle("音声入力開始", for: [])
        recordButton.isEnabled = false
        self.view.addSubview(recordButton)
        //デリゲートの設定
        speechRecognizer.delegate = self
        //ユーザーに音声認識の許可を求める
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    //ユーザが音声認識の許可を出した時
                    self.recordButton.isEnabled = true
                case .denied:
                    //ユーザが音声認識を拒否した時
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                case .restricted:
                    //端末が音声認識に対応していない場合
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                case .notDetermined:
                    //ユーザが音声認識をまだ認証していない時
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    // 録音ボタンが押されたら呼ばれる
    @objc func recordButtonTapped(sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop() // この後に、音声入力結果を成形して、resultのところに動く
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("終了", for: .disabled)
            //録音が停止した！
            print("録音停止")
        } else {
            // 録音を開始する
            massageResult.text = ""
            print("２：録音開始")
            try! startRecording()
            recordButton.setTitle("音声入力終了", for: [])
        }
    }
    
    //録音を開始する
    private func startRecording() throws {
        print("３：録音中")
        // 以前のタスクが実行中の場合はキャンセル
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        
        // 録音用のカテゴリをセット
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let inputNode: AVAudioInputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // オーディオ録音が完了する前に結果が返されるようにリクエストを設定する
        recognitionRequest.shouldReportPartialResults = false
        
        // 認識タスクは、音声認識セッションを表す
        // 取り消すことができるようにタスクへの参照を保持
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                //音声認識の区切りの良いところで実行される。
                print("４：録音完了")
                print(result.bestTranscription.formattedString)
                self.massageResult.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
}
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("音声入力開始", for: [])
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    
    // MARK: SFSpeechRecognizerDelegate
    //speechRecognizerが使用可能かどうかでボタンのisEnabledを変更する
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("音声入力開始", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
}
