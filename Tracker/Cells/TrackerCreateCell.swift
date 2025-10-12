enum TrackerCreateCellType {
    case color
    case image
}

import UIKit

final class TrackerCreateCell : UICollectionViewCell {
    
    
    private var cellType : TrackerCreateCellType = .color
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let colorView : UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        view.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return view
    }()
    
    private var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32) // размер эмодзи
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 32).isActive = true
        label.widthAnchor.constraint(equalToConstant: 38).isActive = true
        return label
    }()
    
    
    private var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 38).isActive = true
        return imageView
    }()
    

    
    func config(type : TrackerCreateCellType, name : String){
        cellType = type
        
        if type == .color {
            setupColor()
            colorView.backgroundColor = UIColor(named: name)
            
        } else if type == .image {
            setupImage()
            emojiLabel.text = name
        }
    }
    
    func setupColor(){
        contentView.addSubview(colorView)
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func setupImage(){
        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    
    func select() {
        switch cellType {
        case .color:
            contentView.layer.cornerRadius = 8
            contentView.backgroundColor = .clear
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = colorView.backgroundColor?.withAlphaComponent(0.3).cgColor
          
        case .image:
            contentView.backgroundColor = .systemGray6
            
            
        }
    }
    
    func deselect() {
        switch cellType {
            case .image:
                contentView.backgroundColor = .clear
                
            case .color:
                contentView.layer.borderWidth = 0
                contentView.layer.borderColor = nil
            }
    }
    
    
}
