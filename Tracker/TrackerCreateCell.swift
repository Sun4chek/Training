//
//  TrackerCreateCell.swift
//  Tracker
//
//  Created by Волошин Александр on 9/17/25.
//
//
//
//enum TrackerCreateCellType {
//    case color
//    case image
//}
//
//import UIKit
//
//final class TrackerCreateCell : UICollectionViewCell {
//    
//    private let colorView : UIView = {
//        let view = UIView()
//        view.layer.cornerRadius = 8
//        view.layer.masksToBounds = true
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        view.widthAnchor.constraint(equalToConstant: 40).isActive = true
//        return view
//    }()
//    
//    private var imageView : UIImageView = {
//        let imageView = UIImageView()
//        imageView.tintColor = .label
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
//        imageView.widthAnchor.constraint(equalToConstant: 38).isActive = true
//        return imageView
//    }()
//    
//    override func
//    
//    func config(type : TrackerCreateCellType, name : String){
//        
//        if type == .color {
//            setupColor()
//            colorView.backgroundColor = UIColor(named: name)
//            
//        } else if type == .image {
//            setupImage()
//            imageView.image = UIImage(systemName: name)
//        }
//    }
//    
//    func setupColor(){
//        contentView.addSubview(colorView)
//    }
//    
//    func setupImage(){
//        contentView.addSubview(imageView)
//    }
//    
//}
