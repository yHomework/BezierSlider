//
//  BezierSlider.swift
//  BezierSlider
//
//  Created by Oleksandr Yevdokymov on 8/10/19.
//  Copyright © 2019 OleksandrYevdokymov. All rights reserved.
//

import UIKit

public protocol BezierSliderDelegate: class {
    func sliderPositionChanged(value: Float)
}

public class BezierSlider: UIView {
    // MARK: - Public properties - Bezier Slider configurations
    public var curvedPath: UIBezierPath? {
        didSet {
            configure()
        }
    }
    
    public var thumbFillColor: UIColor = .white {
        didSet {
            configure()
        }
    }
    
    public var thumbStrokeColor: UIColor = .lightGray {
        didSet {
            configure()
        }
    }
    
    public var thumbLineWidth: CGFloat = 3.0 {
        didSet {
            configure()
        }
    }
    
    public var thumbRect: CGRect = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0) {
        didSet {
            configure()
        }
    }
    
    public var curvedStrokeColor: UIColor = .blue {
        didSet {
            configure()
        }
    }
    
    public var curvedShapeWidth: CGFloat = 3.0 {
        didSet {
            configure()
        }
    }
    
    public weak var delegate: BezierSliderDelegate?
    
    // MARK: - Private Properties
    private var thumbView = UIView()
    private var pathPoints: [CGPoint] = []
    private var pathPointsCount: Int {
        return pathPoints.count
    }
    private var desiredHandleCenter: CGPoint = .zero
    private var handlePathPointIndex: Int = 0
    private var sliderValues: [Float] = []
    
    // MARK: - Public methods
    convenience public init(curvedPath: UIBezierPath, frame: CGRect) {
        self.init(frame: frame)
        self.curvedPath = curvedPath
        configure()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        configure()
    }
    
    // MARK: - Private methods
    private func configure() {
        guard let curvedPath = curvedPath else { return }
        setupCurvedShape(path: curvedPath)
        createPathPoints(path: curvedPath)
        calcuteSliderValues()
        setupThumbView()
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(gestureRecognizer:)))
        thumbView.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func createPathPoints(path: UIBezierPath) {
        let points = PathPoints.createPathPoints(path)
        pathPoints = points.compactMap{ $0 as? CGPoint }
    }
    
    private func setupCurvedShape(path: UIBezierPath) {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = curvedStrokeColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = curvedShapeWidth
        layer.addSublayer(shapeLayer)
    }
    
    private func setupThumbView() {
        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = thumbFillColor.cgColor
        circleLayer.strokeColor = thumbStrokeColor.cgColor
        circleLayer.lineWidth = thumbLineWidth
        circleLayer.path = UIBezierPath(ovalIn: thumbRect).cgPath
        circleLayer.frame = thumbRect
        thumbView = UIView(frame: thumbRect)
        thumbView.layer.addSublayer(circleLayer)
        addSubview(thumbView)
        handleThumbLayout()
    }
    
    func handleThumbLayout() {
        handlePathPointIndex = handlePathPointIndexWith(offset: 0)
        thumbView.center = pathPoints[handlePathPointIndex]
        delegate?.sliderPositionChanged(value: sliderValues[handlePathPointIndex])
    }
    
    func calcuteSliderValues() {
        let step = 1.0 / Float(pathPointsCount)
        var counter: Float = 0.0
        var sliderValues: [Float] = [0.0]
        for _ in 1..<pathPointsCount-1 {
            counter += step
            sliderValues.append(counter)
        }
        sliderValues.append(1.0)
        self.sliderValues = sliderValues
    }
    
    // MARK: - Gesture handler and calculation of Thumb position on curved path
    @objc func panGestureHandler(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            desiredHandleCenter = thumbView.center
        case .changed, .ended, .cancelled:
            let translation = gestureRecognizer.translation(in: self)
            desiredHandleCenter.x += translation.x
            desiredHandleCenter.y += translation.y
            moveHandleToPoint(desiredHandleCenter)
        default:
            break
        }
        gestureRecognizer.setTranslation(.zero, in: self)
    }
    
    func moveHandleToPoint(_ point: CGPoint) {
        let earlierDistance = distanceToPointIfViewMovesByOffset(point, offset: -1)
        let currentDistance = distanceToPointIfViewMovesByOffset(point, offset: 0)
        let laterDistance = distanceToPointIfViewMovesByOffset(point, offset: 1)
        if currentDistance <= earlierDistance && currentDistance <= laterDistance {
            return
        }
        
        let isErlierDistance = earlierDistance < laterDistance
        let direction: Int = isErlierDistance ? -1 : 1
        var distance: CGFloat = isErlierDistance ? earlierDistance : laterDistance
        
        var offset = direction
        while (true) {
            let nextOffset = offset + direction
            let nextDistance = self.distanceToPointIfViewMovesByOffset(point, offset: nextOffset)
            if (nextDistance >= distance) {
                break
            }
            distance = nextDistance
            offset = nextOffset
        }
        handlePathPointIndex += offset
        handleThumbLayout()
    }
    
    func distanceToPointIfViewMovesByOffset(_ point: CGPoint, offset: Int) -> CGFloat {
        let index = handlePathPointIndexWith(offset: offset)
        let proposedHandlePoint = pathPoints[index]
        return CGFloat(hypotf(Float(point.x - proposedHandlePoint.x), Float(point.y - proposedHandlePoint.y)))
    }
    
    func handlePathPointIndexWith(offset: Int) -> Int {
        let index = (handlePathPointIndex + offset) % pathPointsCount
        return index < 0 ? (index + pathPointsCount) : index
    }
}
