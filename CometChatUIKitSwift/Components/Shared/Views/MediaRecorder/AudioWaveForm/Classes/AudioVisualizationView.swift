//
//  AudioVisualizationView.swift
//  Pods
//
//  Created by Bastien Falcou on 12/6/16.
//

import AVFoundation
import UIKit

@objc  class AudioVisualizationView: BaseNibView {
	 enum AudioVisualizationMode {
		case read
		case write
	}

	private enum LevelBarType {
		case upper
		case lower
		case single
	}

	@IBInspectable  var meteringLevelBarWidth: CGFloat = 3.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable  var meteringLevelBarInterItem: CGFloat = 2.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable  var meteringLevelBarCornerRadius: CGFloat = 2.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable  var meteringLevelBarSingleStick: Bool = false {
		didSet {
			self.setNeedsDisplay()
		}
	}

	 var audioVisualizationMode: AudioVisualizationMode = .read

	 var audioVisualizationTimeInterval: TimeInterval = 0.05 // Time interval between each metering bar representation

	// Specify a `gradientPercentage` to have the width of gradient be that percentage of the view width (starting from left)
	// The rest of the screen will be filled by `self.gradientStartColor` to display nicely.
	// Do not specify any `gradientPercentage` for gradient calculating fitting size automatically.
	 var currentGradientPercentage: Float?

	private var meteringLevelsArray: [Float] = []    // Mutating recording array (values are percentage: 0.0 to 1.0)
	private var meteringLevelsClusteredArray: [Float] = [] // Generated read mode array (values are percentage: 0.0 to 1.0)

	private var currentMeteringLevelsArray: [Float] {
		if !self.meteringLevelsClusteredArray.isEmpty {
			return meteringLevelsClusteredArray
		}
		return meteringLevelsArray
	}

	private var playChronometer: Chronometer?

	 var meteringLevels: [Float]? {
		didSet {
			if let meteringLevels = self.meteringLevels {
				self.meteringLevelsClusteredArray = meteringLevels
				self.currentGradientPercentage = 0.0
				_ = self.scaleSoundDataToFitScreen()
			}
		}
	}

	static var audioVisualizationDefaultGradientStartColor: UIColor {
       return CometChatTheme_v4.palatte.primary

	}
	static var audioVisualizationDefaultGradientEndColor: UIColor {
        return CometChatTheme_v4.palatte.primary
	}

	@IBInspectable  var gradientStartColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientStartColor {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable  var gradientEndColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientEndColor {
		didSet {
			self.setNeedsDisplay()
		}
	}

	override  init(frame: CGRect) {
		super.init(frame: frame)
	}

	required  init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override  func draw(_ rect: CGRect) {
		super.draw(rect)

		if let context = UIGraphicsGetCurrentContext() {
			self.drawLevelBarsMaskAndGradient(inContext: context)
		}
	}

	 func reset() {
		self.meteringLevels = nil
		self.currentGradientPercentage = nil
		self.meteringLevelsClusteredArray.removeAll()
		self.meteringLevelsArray.removeAll()
		self.setNeedsDisplay()
	}

	// MARK: - Record Mode Handling

	 func add(meteringLevel: Float) {
		guard self.audioVisualizationMode == .write else {
			fatalError("trying to populate audio visualization view in read mode")
		}

		self.meteringLevelsArray.append(meteringLevel)
		self.setNeedsDisplay()
	}

	 func scaleSoundDataToFitScreen() -> [Float] {
		if self.meteringLevelsArray.isEmpty {
			return []
		}

		self.meteringLevelsClusteredArray.removeAll()
		var lastPosition: Int = 0

		for index in 0..<self.maximumNumberBars {
			let position: Float = Float(index) / Float(self.maximumNumberBars) * Float(self.meteringLevelsArray.count)
			var h: Float = 0.0

			if self.maximumNumberBars > self.meteringLevelsArray.count && floor(position) != position {
				let low: Int = Int(floor(position))
				let high: Int = Int(ceil(position))

				if high < self.meteringLevelsArray.count {
					h = self.meteringLevelsArray[low] + ((position - Float(low)) * (self.meteringLevelsArray[high] - self.meteringLevelsArray[low]))
				} else {
					h = self.meteringLevelsArray[low]
				}
			} else {
				for nestedIndex in lastPosition...Int(position) {
					h += self.meteringLevelsArray[nestedIndex]
				}
				let stepsNumber = Int(1 + position - Float(lastPosition))
				h = h / Float(stepsNumber)
			}

			lastPosition = Int(position)
			self.meteringLevelsClusteredArray.append(h)
		}
		self.setNeedsDisplay()
		return self.meteringLevelsClusteredArray
	}

	// PRAGMA: - Play Mode Handling

	 func play(from url: URL) {
		guard self.audioVisualizationMode == .read else {
			fatalError("trying to read audio visualization in write mode")
		}

		AudioContext.load(fromAudioURL: url) { audioContext in
			guard let audioContext = audioContext else {
				fatalError("Couldn't create the audioContext")
			}
			self.meteringLevels = audioContext.render(targetSamples: 100)
			self.play(for: 10)
		}
	}

	 func play(for duration: TimeInterval) {
		guard self.audioVisualizationMode == .read else {
			fatalError("trying to read audio visualization in write mode")
		}

		guard self.meteringLevels != nil else {
			fatalError("trying to read audio visualization of non initialized sound record")
		}

		if let currentChronometer = self.playChronometer {
			currentChronometer.start() // resume current
			return
		}

		self.playChronometer = Chronometer(withTimeInterval: self.audioVisualizationTimeInterval)
		self.playChronometer?.start(shouldFire: false)

		self.playChronometer?.timerDidUpdate = { [weak self] timerDuration in
			guard let this = self else {
				return
			}

			if timerDuration >= duration {
				this.stop()
				return
			}
            
            DispatchQueue.main.async {
                this.currentGradientPercentage = Float(timerDuration) / Float(duration)
                this.setNeedsDisplay()
            }
		}
	}

	 func pause() {
		guard let chronometer = self.playChronometer, chronometer.isPlaying else {
			fatalError("trying to pause audio visualization view when not playing")
		}
		self.playChronometer?.pause()
	}

	 func stop() {
		self.playChronometer?.stop()
		self.playChronometer = nil

		self.currentGradientPercentage = 1.0
		self.setNeedsDisplay()
		self.currentGradientPercentage = nil
	}

	// MARK: - Mask + Gradient

	private func drawLevelBarsMaskAndGradient(inContext context: CGContext) {
		if self.currentMeteringLevelsArray.isEmpty {
			return
		}

		context.saveGState()

		UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)

		let maskContext = UIGraphicsGetCurrentContext()
		UIColor.black.set()

		self.drawMeteringLevelBars(inContext: maskContext!)

		let mask = UIGraphicsGetCurrentContext()?.makeImage()
		UIGraphicsEndImageContext()

		context.clip(to: self.bounds, mask: mask!)

		self.drawGradient(inContext: context)

		context.restoreGState()
	}

	private func drawGradient(inContext context: CGContext) {
		if self.currentMeteringLevelsArray.isEmpty {
			return
		}

		context.saveGState()

		let startPoint = CGPoint(x: 0.0, y: self.centerY)
		var endPoint = CGPoint(x: self.xLeftMostBar() + self.meteringLevelBarWidth, y: self.centerY)

		if let gradientPercentage = self.currentGradientPercentage {
			endPoint = CGPoint(x: self.frame.size.width * CGFloat(gradientPercentage), y: self.centerY)
		}

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let colorLocations: [CGFloat] = [0.0, 1.0]
		let colors = [self.gradientStartColor.cgColor, self.gradientEndColor.cgColor]

		let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)

		context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))

		context.restoreGState()

		if self.currentGradientPercentage != nil {
			self.drawPlainBackground(inContext: context, fillFromXCoordinate: endPoint.x)
		}
	}

	private func drawPlainBackground(inContext context: CGContext, fillFromXCoordinate xCoordinate: CGFloat) {
		context.saveGState()

		let squarePath = UIBezierPath()

		squarePath.move(to: CGPoint(x: xCoordinate, y: 0.0))
		squarePath.addLine(to: CGPoint(x: self.frame.size.width, y: 0.0))
		squarePath.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height))
		squarePath.addLine(to: CGPoint(x: xCoordinate, y: self.frame.size.height))

		squarePath.close()
		squarePath.addClip()

		self.gradientStartColor.setFill()
		squarePath.fill()

		context.restoreGState()
	}

	// MARK: - Bars

	private func drawMeteringLevelBars(inContext context: CGContext) {
		let offset = max(self.currentMeteringLevelsArray.count - self.maximumNumberBars, 0)

		for index in offset..<self.currentMeteringLevelsArray.count {
			if self.meteringLevelBarSingleStick {
				self.drawBar(index - offset, meteringLevelIndex: index, levelBarType: .single, context: context)
			} else {
				self.drawBar(index - offset, meteringLevelIndex: index, levelBarType: .upper, context: context)
				self.drawBar(index - offset, meteringLevelIndex: index, levelBarType: .lower, context: context)
			}
		}
	}

	private func drawBar(_ barIndex: Int, meteringLevelIndex: Int, levelBarType: LevelBarType, context: CGContext) {
		context.saveGState()

		var barRect: CGRect

		let xPointForMeteringLevel = self.xPointForMeteringLevel(barIndex)
		let heightForMeteringLevel = self.heightForMeteringLevel(self.currentMeteringLevelsArray[meteringLevelIndex])

		switch levelBarType {
		case .upper:
			barRect = CGRect(x: xPointForMeteringLevel,
							 y: self.centerY - heightForMeteringLevel,
							 width: self.meteringLevelBarWidth,
							 height: heightForMeteringLevel)
		case .lower:
			barRect = CGRect(x: xPointForMeteringLevel,
							 y: self.centerY,
							 width: self.meteringLevelBarWidth,
							 height: heightForMeteringLevel)
		case .single:
			barRect = CGRect(x: xPointForMeteringLevel,
							 y: self.centerY - heightForMeteringLevel,
							 width: self.meteringLevelBarWidth,
							 height: heightForMeteringLevel * 2)
		}

		let barPath: UIBezierPath = UIBezierPath(roundedRect: barRect, cornerRadius: self.meteringLevelBarCornerRadius)

		UIColor.black.set()
		barPath.fill()

		context.restoreGState()
	}

	// MARK: - Points Helpers

	private var centerY: CGFloat {
		return self.frame.size.height / 2.0
	}

	private var maximumBarHeight: CGFloat {
		return self.frame.size.height / 2.0
	}

	private var maximumNumberBars: Int {
		return Int(self.frame.size.width / (self.meteringLevelBarWidth + self.meteringLevelBarInterItem))
	}

	private func xLeftMostBar() -> CGFloat {
		return self.xPointForMeteringLevel(min(self.maximumNumberBars - 1, self.currentMeteringLevelsArray.count - 1))
	}

	private func heightForMeteringLevel(_ meteringLevel: Float) -> CGFloat {
		return CGFloat(meteringLevel) * self.maximumBarHeight
	}

	private func xPointForMeteringLevel(_ atIndex: Int) -> CGFloat {
		return CGFloat(atIndex) * (self.meteringLevelBarWidth + self.meteringLevelBarInterItem)
	}
}
