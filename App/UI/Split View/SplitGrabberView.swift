//
//  SplitGrabberView.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 11/4/21.
//

import UIKit

protocol SplitGrabberViewDelegate: AnyObject {
	func splitGrabberViewDidBeginDragging(_ splitGrabberView: SplitGrabberView)
	func splitGrabberView(_ splitGrabberView: SplitGrabberView, splitDidChange delta: CGFloat)
	func splitGrabberViewDidCommit(_ splitGrabberView: SplitGrabberView)
	func splitGrabberViewDidCancel(_ splitGrabberView: SplitGrabberView)
}

class SplitGrabberView: UIView {

	private(set) var axis: NSLayoutConstraint.Axis
	weak var delegate: SplitGrabberViewDelegate?

	private var pillView: UIView!

	init(axis: NSLayoutConstraint.Axis) {
		self.axis = axis
		super.init(frame: .zero)

		backgroundColor = .black

		let pillContainerView = UIView()
		pillContainerView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(pillContainerView)

		pillView = UIView()
		pillView.translatesAutoresizingMaskIntoConstraints = false
		pillView.backgroundColor = .white
		pillView.alpha = 0.55
		pillView.layer.cornerRadius = 2
		pillContainerView.addSubview(pillView)

		let scaleFactor = UIDevice.current.userInterfaceIdiom == .mac ? 0.7 : 1
		let selfWidth: CGFloat = floor(10 * scaleFactor)
		let pillWidth: CGFloat = floor(4 * scaleFactor)
		let pillHeight: CGFloat = floor(44 * scaleFactor)
		let pillSpacingX: CGFloat = floor(3 * scaleFactor)
		let pillSpacingY: CGFloat = floor(12 * scaleFactor)
		NSLayoutConstraint.activate([
				.vertical: [
					self.heightAnchor.constraint(equalToConstant: selfWidth),
					pillView.widthAnchor.constraint(equalToConstant: pillHeight),
					pillView.heightAnchor.constraint(equalToConstant: pillWidth),
					pillView.leadingAnchor.constraint(equalTo: pillContainerView.leadingAnchor, constant: pillSpacingY),
					pillView.trailingAnchor.constraint(equalTo: pillContainerView.trailingAnchor, constant: -pillSpacingY),
					pillView.topAnchor.constraint(equalTo: pillContainerView.topAnchor, constant: pillSpacingX),
					pillView.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -pillSpacingX)
				],
				.horizontal: [
					self.widthAnchor.constraint(equalToConstant: selfWidth),
					pillView.heightAnchor.constraint(equalToConstant: pillHeight),
					pillView.widthAnchor.constraint(equalToConstant: pillWidth),
					pillView.leadingAnchor.constraint(equalTo: pillContainerView.leadingAnchor, constant: pillSpacingX),
					pillView.trailingAnchor.constraint(equalTo: pillContainerView.trailingAnchor, constant: -pillSpacingX),
					pillView.topAnchor.constraint(equalTo: pillContainerView.topAnchor, constant: pillSpacingY),
					pillView.bottomAnchor.constraint(equalTo: pillContainerView.bottomAnchor, constant: -pillSpacingY)
				]
		][axis]!)

		NSLayoutConstraint.activate([
			pillContainerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
			pillContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
		])

		// Mac: Entire bar is a grabber.
		// iOS: Just the pill is a grabber.
		// Matches expected behaviour of split views on each platform.
		#if targetEnvironment(macCatalyst)
		let grabbyView = self
		#else
		let grabbyView = pillContainerView
		#endif
		grabbyView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognizerFired)))

		#if targetEnvironment(macCatalyst)
		addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(self.hoverGestureRecognizerFired)))
		#endif

		pillContainerView.addInteraction(UIPointerInteraction(delegate: self))
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func panGestureRecognizerFired(_ gestureRecognizer: UIPanGestureRecognizer) {
		switch gestureRecognizer.state {
		case .began:
			delegate?.splitGrabberViewDidBeginDragging(self)
			
		case .changed:
			let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
			let value: CGFloat
			switch axis {
			case .horizontal: value = translation.x
			case .vertical:   value = translation.y
			@unknown default: fatalError()
			}
			delegate?.splitGrabberView(self, splitDidChange: value)
			break

		case .ended:
			delegate?.splitGrabberViewDidCommit(self)
			break

		case .failed, .cancelled:
			delegate?.splitGrabberViewDidCancel(self)
			break

		case .possible: break
		@unknown default: break
		}
	}

	#if targetEnvironment(macCatalyst)
	@objc private func hoverGestureRecognizerFired(_ gestureRecognizer: UIHoverGestureRecognizer) {
		// Handles hover state and cursor.
		switch gestureRecognizer.state {
		case .began, .changed:
			UIView.animate(withDuration: 0.2) {
				self.pillView.alpha = 1
			}

			switch axis {
			case .horizontal: NSCursor.resizeLeftRight.set()
			case .vertical:   NSCursor.resizeUpDown.set()
			@unknown default: fatalError()
			}

		case .ended, .failed, .cancelled:
			UIView.animate(withDuration: 0.2) {
				self.pillView.alpha = 0.55
			}

			NSCursor.arrow.set()

		case .possible:   break
		@unknown default: break
		}
	}
	#endif

}

@available(iOS 13.4, *)
extension SplitGrabberView: UIPointerInteractionDelegate {

	func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
		let rectFrame: CGRect
		switch axis {
		case .horizontal: rectFrame = pillView.frame.insetBy(dx: -2, dy: -5)
		case .vertical:   rectFrame = pillView.frame.insetBy(dx: -5, dy: -2)
		@unknown default: fatalError()
		}
		return UIPointerStyle(effect: .highlight(UITargetedPreview(view: pillView)),
													shape: .roundedRect(rectFrame, radius: 7))
	}

}
