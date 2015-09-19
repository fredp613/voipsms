import UIKit

let incomingTag = 0, outgoingTag = 1
let bubbleTag = 8

class CustomTextViewForCell : UITextView, UITextViewDelegate {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: CGRectZero, textContainer: nil)
        self.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        print("hi")
        return true
    }
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        print("asdf")
        return false
    }
}


class MessageBubbleCell: UITableViewCell, TTTAttributedLabelDelegate  {
    let bubbleImageView: UIImageView
    let messageLabel: TTTAttributedLabel
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        bubbleImageView = UIImageView(image: bubbleImage.incoming, highlightedImage: bubbleImage.incomingHighlighed)
        bubbleImageView.tag = bubbleTag
        bubbleImageView.userInteractionEnabled = true // #CopyMesage
        messageLabel = TTTAttributedLabel(frame: CGRectZero)

//        messageLabel.font = UIFont.systemFontOfSize(messageFontSize)
        messageLabel.numberOfLines = 0
//        messageLabel.textContainer.lineBreakMode = NSLineBreakMode.ByWordWrapping
//        messageLabel.scrollEnabled = false
//        messageLabel.backgroundColor = UIColor.clearColor()
//        messageLabel.dataDetectorTypes = UIDataDetectorTypes.Link | UIDataDetectorTypes.PhoneNumber | UIDataDetectorTypes.Address //| UIDataDetectorTypes.CalendarEvent
//        messageLabel.editable = false
//        messageLabel.selectable = true
//        messageLabel.userInteractionEnabled = true
//        messageLabel.contentInset = UIEdgeInsets(top: -8, left: 0, bottom: 0, right: 0)
//        messageLabel.contentSize.width = 218


        messageLabel.preferredMaxLayoutWidth = 218

        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None
        messageLabel.delegate = self
        
        contentView.addSubview(bubbleImageView)
        bubbleImageView.addSubview(messageLabel)
        
        
        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraint(NSLayoutConstraint(item: bubbleImageView, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: 10))
        contentView.addConstraint(NSLayoutConstraint(item: bubbleImageView, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 4.5))
        bubbleImageView.addConstraint(NSLayoutConstraint(item: bubbleImageView, attribute: .Width, relatedBy: .Equal, toItem: messageLabel, attribute: .Width, multiplier: 1, constant: 30))
        contentView.addConstraint(NSLayoutConstraint(item: bubbleImageView, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1, constant: -4.5))
        
        bubbleImageView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .CenterX, relatedBy: .Equal, toItem: bubbleImageView, attribute: .CenterX, multiplier: 1, constant: 3))
        bubbleImageView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .CenterY, relatedBy: .Equal, toItem: bubbleImageView, attribute: .CenterY, multiplier: 1, constant: -0.5))

        bubbleImageView.addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .Height, relatedBy: .Equal, toItem: bubbleImageView, attribute: .Height, multiplier: 1, constant: -15))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureWithMessage(message: CoreMessage) {
        let messageFont:UIFont? = UIFont(name: "Helvetica", size: 15.0)
        let dateFont:UIFont? = UIFont(name: "Helvetica-Oblique", size: 12.0)
        let mutableStr = NSMutableAttributedString()
        var humanDate = String()
        if message.date != "" {
            humanDate = message.date.dateFormattedString()
        } else {
            humanDate = message.date
        }
        var textColor : UIColor!
        if message.type.boolValue == true {
            textColor = UIColor.blackColor()
        } else {
            textColor = UIColor.whiteColor()
        }
        
        let dateStr = NSAttributedString(string: "\n\(humanDate)", attributes:
            [NSForegroundColorAttributeName: textColor,
                NSFontAttributeName: dateFont!])
        let messageStr = NSAttributedString(string: message.message, attributes:
            [NSForegroundColorAttributeName: textColor,
                NSFontAttributeName: messageFont!])
        
        mutableStr.appendAttributedString(messageStr)
        if message.date != "" {
            mutableStr.appendAttributedString(dateStr)
        }
        

        messageLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue | NSTextCheckingType.PhoneNumber.rawValue
        if message.type.boolValue == false {
            messageLabel.linkAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor().CGColor, NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
            messageLabel.activeLinkAttributes = [NSForegroundColorAttributeName: UIColor.lightGrayColor().CGColor, NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleNone.rawValue]
        } else {
            messageLabel.linkAttributes = [NSForegroundColorAttributeName : UIColor.darkTextColor().CGColor, NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
            messageLabel.activeLinkAttributes = [NSForegroundColorAttributeName: UIColor.lightGrayColor().CGColor, NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleNone.rawValue]
        }

//        messageLabel.enabledTextCheckingTypes = NSTextCheckingType.PhoneNumber.rawValue

//        messageLabel.attributedText = mutableStr
        messageLabel.setText(mutableStr)
//        messageLabel.text = message.message
        
        
//        
//        let types: NSTextCheckingType = NSTextCheckingType.Address | NSTextCheckingType.PhoneNumber | NSTextCheckingType.Link
//        var error: NSError?
//        let detector = NSDataDetector(types: types.rawValue, error: &error)
//        detector?.enumerateMatchesInString(message.message, options: nil, range: NSMakeRange(0, (message.message as NSString).length), usingBlock: { (result, flags, _) -> Void in
//            if result.resultType == NSTextCheckingType.Link {
//                println(result.URL!)
//                println(result.range)
//                var textToEvaluate = NSString(string: "\(mutableStr)").substringWithRange(result.range)
//                mutableStr.mutableString.replaceCharactersInRange(result.range, withString: "asdfsdf")
//            }
//
//            if result.resultType == NSTextCheckingType.PhoneNumber {
//                println(result.phoneNumber!)
//            }
//            
////            if result.resultType == NSTextCheckingType.Address {
////                println(result.addressComponents!)
////            }
//            
//        })
        
            var layoutAttribute: NSLayoutAttribute
            var layoutConstant: CGFloat
            
            if message.type == 1 || message.type == true {
//                tag = incomingTag
                bubbleImageView.image = bubbleImage.incoming
                bubbleImageView.highlightedImage = bubbleImage.incomingHighlighed
//                messageLabel.textColor = UIColor.blackColor()
                layoutAttribute = .Left
                layoutConstant = 10
                
            } else { // outgoing
//                tag = outgoingTag
                bubbleImageView.image = bubbleImage.outgoing
                bubbleImageView.highlightedImage = bubbleImage.outgoingHighlighed
//                messageLabel.textColor = UIColor.whiteColor()
                layoutAttribute = .Right
                layoutConstant = -10
                
//                let attributes : [NSObject: AnyObject] = [NSForegroundColorAttributeName:UIColor.whiteColor(), NSUnderlineStyleAttributeName: 1]
//                messageLabel.linkTextAttributes = attributes
            }
            
            let layoutConstraint: NSLayoutConstraint = bubbleImageView.constraints[1] // `messageLabel` CenterX
            layoutConstraint.constant = -layoutConstraint.constant
            
            let constraints: NSArray = contentView.constraints
            let indexOfConstraint = constraints.indexOfObjectPassingTest { (constraint, idx, stop) in
                return (constraint.firstItem as! UIView).tag == bubbleTag && (constraint.firstAttribute == NSLayoutAttribute.Left || constraint.firstAttribute == NSLayoutAttribute.Right)
            }
            contentView.removeConstraint(constraints[indexOfConstraint] as! NSLayoutConstraint)
            contentView.addConstraint(NSLayoutConstraint(item: bubbleImageView, attribute: layoutAttribute, relatedBy: .Equal, toItem: contentView, attribute: layoutAttribute, multiplier: 1, constant: layoutConstant))
        
    }
    
    // Highlight cell #CopyMessage
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        bubbleImageView.highlighted = selected
    }
    
    //MARK: TTTAttributedLabel delegate methods
    func attributedLabel(label: TTTAttributedLabel!, didLongPressLinkWithURL url: NSURL!, atPoint point: CGPoint) {
        print("did select link")
        UIApplication.sharedApplication().openURL(url)
    }
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithPhoneNumber phoneNumber: String!) {
        let actionablePN = "tel://" + phoneNumber
        UIApplication.sharedApplication().openURL(NSURL(string: actionablePN)!)
    }
}

let bubbleImage = bubbleImageMake()

func bubbleImageMake() -> (incoming: UIImage, incomingHighlighed: UIImage, outgoing: UIImage, outgoingHighlighed: UIImage) {
    let maskOutgoing = UIImage(named: "MessageBubble")!
    let maskIncoming = UIImage(CGImage: maskOutgoing.CGImage!, scale: 2, orientation: .UpMirrored)
    
    let capInsetsIncoming = UIEdgeInsets(top: 17, left: 26.5, bottom: 17.5, right: 21)
    let capInsetsOutgoing = UIEdgeInsets(top: 17, left: 21, bottom: 17.5, right: 26.5)
    
    let incoming = coloredImage(maskIncoming, red: 229/255.0, green: 229/255.0, blue: 234/255.0, alpha: 1).resizableImageWithCapInsets(capInsetsIncoming)
    _ = coloredImage(maskIncoming, red: 206/255.0, green: 206/255.0, blue: 210/255.0, alpha: 1).resizableImageWithCapInsets(capInsetsIncoming)
    
//    UIColor(red: 179/255, green: 176/255, blue: 77/255, alpha: 1)
    let outgoing = coloredImage(maskOutgoing, red: 116/255.0, green: 136/255.0, blue: 195/255.0, alpha: 1).resizableImageWithCapInsets(capInsetsOutgoing)
    _ = coloredImage(maskOutgoing, red: 116/255.0, green: 136/255.0, blue: 195/255.0, alpha: 0.7).resizableImageWithCapInsets(capInsetsOutgoing)
    
//    return (incoming, incomingHighlighted, outgoing, outgoingHighlighted)
    return (incoming, incoming, outgoing, outgoing)
}

func coloredImage(image: UIImage, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIImage! {
    let rect = CGRect(origin: CGPointZero, size: image.size)
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    let context = UIGraphicsGetCurrentContext()
    image.drawInRect(rect)
    CGContextSetRGBFillColor(context, red, green, blue, alpha)
    CGContextSetBlendMode(context, CGBlendMode.SourceAtop)
    CGContextFillRect(context, rect)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result
}





