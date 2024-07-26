/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

/// A Lexical frontend that is optimised for consumption. No scrolling, selection, or editing.
@objc public class LexicalReadOnlyView: UIView {

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    self.addGestureRecognizer(tapGestureRecognizer)
    self.clipsToBounds = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: -

  @objc public var textKitContext: LexicalReadOnlyTextKitContext? {
    willSet {
      if let oldContext = textKitContext, newValue !== textKitContext {
        oldContext.attachedView = nil
      }
    }
    didSet {
      textKitContext?.attachedView = self
      setNeedsDisplay()
    }
  }

  override public func layoutSubviews() {
    self.backgroundColor = .clear
    super.layoutSubviews()
    guard let textKitContext else {
      return
    }
    textKitContext.viewDidLayoutSubviews(viewBounds: self.bounds)
  }

  override public func draw(_ rect: CGRect) {
    if let textKitContext,
       let graphicsContext = UIGraphicsGetCurrentContext() {
      textKitContext.draw(inContext: graphicsContext)
    }
  }

  @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
    guard let textKitContext else { return }
    let pointInView = gestureRecognizer.location(in: self)
    let pointInTextContainer = CGPoint(x: pointInView.x - textKitContext.textContainerInsets.left,
                                       y: pointInView.y - textKitContext.textContainerInsets.top)

    if let truncationRect = textKitContext.sizeCache.customTruncationRect {
      if truncationRect.contains(pointInTextContainer) {
        textKitContext.editor.dispatchCommand(type: .truncationIndicatorTapped, payload: nil)
        return
      }
    }

    var partialFraction: CGFloat = 0
    let indexOfCharacter = textKitContext.layoutManager.characterIndex(for: pointInTextContainer,
                                                                       in: textKitContext.textContainer,
                                                                       fractionOfDistanceBetweenInsertionPoints: &partialFraction)

    if indexOfCharacter == textKitContext.textStorage.length - 1 && partialFraction == 1.0 {
      textKitContext.editor.dispatchCommand(type: .readOnlyViewTapped, payload: nil)
      return
    }

    let attributes = textKitContext.textStorage.attributes(at: indexOfCharacter, effectiveRange: nil)

    if let entity = attributes[.link] {
      if let link = entity as? URL {
        textKitContext.editor.dispatchCommand(type: .linkTapped, payload: link)
        return
      } else if let link = entity as? String {
        if let linkURL = URL(string: link) {
          textKitContext.editor.dispatchCommand(type: .linkTapped, payload: linkURL)
          return
        }
      } else {
        textKitContext.editor.dispatchCommand(type: .entityTapped, payload: entity)
      }
    }

    textKitContext.editor.dispatchCommand(type: .readOnlyViewTapped, payload: nil)
  }
}
