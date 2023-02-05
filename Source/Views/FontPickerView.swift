//
//  FontPickerView.swift
//  
//
//  Created by Joshua Russell on 2023-02-04.
//

import UIKit

final class FontPickerView: UIView {

    private let picker = UIPickerView()
    
    private var selectedFontName: String = "ArialRoundedMTBold" {
        didSet {
            selectedFont = selectedFontName
        }
    }
    private var selectedFont: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: topAnchor),
            picker.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        picker.dataSource = self
        picker.delegate = self
        picker.center = center

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(selectedFont: String) {
        self.selectedFont = selectedFont
        
        guard let fontNameIndex = UIFont.nameOf.allCases.firstIndex(where: { $0.rawValue == selectedFont }) else {
                  return
              
              }
        selectedFontName = selectedFont
        picker.selectRow(fontNameIndex, inComponent: 0, animated: true)
    }
}

extension FontPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        UIFont.nameOf.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        guard let font = UIFont.nameOf.allCases[safe: row] else {
            return
        }
        
        selectedFontName = font.rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        label.textAlignment = .center
        guard let fontName = UIFont.nameOf.allCases[safe: row] else {
            return label
        }
        
        guard let font = UIFont(name: fontName.rawValue, size: 14) else {
            return label
        }
        
        let attributedText = NSAttributedString(
            string: fontName.rawValue,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.white])
        label.attributedText = attributedText
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        40
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        40
    }
}


