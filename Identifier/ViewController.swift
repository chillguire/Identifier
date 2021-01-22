//
//  ViewController.swift
//  Identifier
//
//  Created by Ricardo Avendaño on 8/22/20.
//  Copyright © 2020 Ricardo Avendaño. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Social

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var identifierLabel: UILabel!
	@IBOutlet weak var homeImage: UIImageView!
	
	
	let imagePicker = UIImagePickerController()
	
	var identifiedObject : String = ""
	var identifiedConfidence : VNConfidence = 0.0
	var identifiedImage : UIImage = UIImage(named: "question-mark.png")!
	
	// MARK: - View loads
	override func viewDidLoad() {
		super.viewDidLoad()
		
		shareButton.isHidden = true
		identifierLabel.isHidden = true
		
		imagePicker.delegate = self
		
		imagePicker.sourceType = .photoLibrary//camera
		imagePicker.allowsEditing = false
		
	}
	
	// MARK: - User has picked an image
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		
		if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
			imageView.image = selectedImage
			
			homeImage.isHidden = true
			
			imagePicker.dismiss(animated: true, completion: nil)
			
			identifiedImage = selectedImage
		
			guard let coreImage = CIImage(image: selectedImage) else {
				fatalError("Could not convert to CIImage.")
			}
			
			detect(image: coreImage)
			
		} else {
			print("Problem with the image.")
		}
	
	}
	
	// MARK: - Detect
	func detect(image: CIImage) {
		
		guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
			fatalError("Loading CoreML model failed.")
		}
		
		let request = VNCoreMLRequest(model: model) { (request, error) in
			
			guard let results = request.results as? [VNClassificationObservation] else {
				fatalError("Could not fetch request nor process image")
			}
			
			self.classify(results: results)
		}
		
		let handler = VNImageRequestHandler(ciImage: image)
		do {
			try handler.perform([request])
		} catch {
			print(error)
		}
	}
	
	// MARK: - Classify
	func classify(results: [VNClassificationObservation]) {
		
		for index in 0..<results.count{
			if results[index].confidence >= 0.55 {
				//print(results[index].identifier)
				
				identifiedObject = results[index].identifier
				identifiedConfidence = results[index].confidence
				DispatchQueue.main.async {
					self.identifierLabel.text = String(format: "This is a \(results[index].identifier).\n(%.2f)", results[index].confidence * 100)
					self.shareButton.isHidden = false
					self.identifierLabel.isHidden = false
				}
				break
			} else {
				//print(results[index].identifier)
				
				identifiedObject = results[index].identifier
				identifiedConfidence = results[index].confidence
				DispatchQueue.main.async {
										
					self.identifierLabel.text = String(format: "I think this is a \(results[index].identifier) (%.2f) or a \(results[index + 1].identifier) (%.2f); but I'm not certain.",results[index].confidence * 100,results[index+1].confidence * 100)
					self.shareButton.isHidden = false
					self.identifierLabel.isHidden = false
				}
				break
			}
		}
	}

	// MARK: - Camera bar button gets tapped
	@IBAction func cameraTapped(_ sender: UIBarButtonItem) {
		present(imagePicker, animated: true, completion: nil)
	}
	
	// MARK: - Share button gets tapped
	@IBAction func shareTapped(_ sender: UIButton) {
		
		
	let string = String(format: "This is a \(identifiedObject); identified with a neural network with %.2f of precision! Made by Identifier app.", identifiedConfidence * 100)
	let url = URL(string: "https://github.com/chillguire")!
	let image : UIImage = identifiedImage

	let activityViewController =
	    UIActivityViewController(activityItems: [string, url, image],
						    applicationActivities: nil)
 
	present(activityViewController, animated: true)
		
	}
}

