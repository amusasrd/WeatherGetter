//
//  ViewController.swift
//  iWeather
//
//  Created by Ahmed Musa on 29/12/16.
//  Copyright © 2016 Moses Apps. All rights reserved.
//

import UIKit
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ViewController: UIViewController, WeatherGetterDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cloudCoverLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var rainLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var getLocationWeatherButton: UIButton!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var getCityWeatherButton: UIButton!
    
    let locationManager = CLLocationManager()
    var weather: WeatherGetter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        weather = WeatherGetter(delegate: self)
        
        //initiaise UI
        
        cityLabel.text = "iWeather"
        weatherLabel.text = "" 
        temperatureLabel.text = ""
        cloudCoverLabel.text = ""
        windLabel.text = ""
        rainLabel.text = ""
        humidityLabel.text = ""
        cityTextField.text = ""
        cityTextField.placeholder = "Enter city name to get its weather..."
        cityTextField.delegate = self
        cityTextField.enablesReturnKeyAutomatically = true
        getCityWeatherButton.isEnabled = false
        
        getLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   //button events and states
    
    @IBAction func getWeatherForLocationButtonTapped(_ sender: UIButton) {
        setWeatherButtonStates(false)
        getLocation()
    }
    
    @IBAction func getWeatherForCityButtonTapped(_ sender: UIButton) {
        guard let text = cityTextField.text, !text.trimmed.isEmpty else {
            return
        }
        setWeatherButtonStates(false)
        weather.getWeatherByCity(cityTextField.text!.urlEncoded)
    }
    
    func setWeatherButtonStates(_ state: Bool) {
        
        getLocationWeatherButton.isEnabled = state
        getCityWeatherButton.isEnabled = state
    }

    //weatherGetterDelegate methods
    
    func didGetWeather(_ weather: Weather) {
    //This method is called asynchronously, which means it won't execute in the main queue. All UI code needs to execute in the main queue, which is why we're wrapping the code that updates all the labels in a dispatch_async() call.
        
        DispatchQueue.main.async {
            self.cityLabel.text = weather.city
            self.weatherLabel.text = weather.weatherDescription
            self.temperatureLabel.text = "\(Int(round(weather.tempCelsius)))°"
            self.cloudCoverLabel.text = "\(weather.cloudCover)%"
            self.windLabel.text = "\(weather.windSpeed) m/s"
            
            if let rain = weather.rainfallInLast3Hours {
                self.rainLabel.text = "\(rain) mm"
            }
            else {
                self.rainLabel.text = "None"
            }
        
            self.humidityLabel.text = "\(weather.humidity)%"
            self.getLocationWeatherButton.isEnabled = true
            self.getCityWeatherButton.isEnabled = self.cityTextField.text?.characters.count > 0
        }
    }
    
    func didNotGetWeather(_ error: NSError) {
//This method is called asynchronously, which means it won't execute in the main queue. All UI code needs to execute in the main queue, which is why we're wrapping the call to showSimpleAlert(title:message:) in a dispatch_async() call.

        DispatchQueue.main.async {
            self.showSimpleAlert(title: "Can't get the weather", message: "The weather service isn't responding.")
            self.getLocationWeatherButton.isEnabled = true
            self.getCityWeatherButton.isEnabled = self.cityTextField.text?.characters.count > 0
        }
        print("didNotGetWeather error: \(error)")
    }
    
    
    //CLLocationManagerDelegate and related methods.
    func getLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            showSimpleAlert( title: "Please turn on location services", message: "This app needs location services in order to report the weather " + "for your current location. \n" + "Go to Settings → Privacy → Location services and turn location services on.")
            getLocationWeatherButton.isEnabled = true
            return
        }
        
        let authStatus = CLLocationManager.authorizationStatus()
        guard authStatus == .authorizedWhenInUse else {
            switch authStatus {
            case .denied, .restricted:
                let alert = UIAlertController(title: "Location services for this app are disabled", message: "In order to get your current location, please open Settings for this app, choose \"Location\"and set \"Allow location access\" to \"While Using the App\".", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default) {
                    action in
                    if let url = URL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.openURL(url)
                    }
                }
                
                alert.addAction(cancelAction)
                alert.addAction(openSettingsAction)
                present(alert, animated: true, completion: nil)
                getLocationWeatherButton.isEnabled = true
                return
                
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                
            default:
                print("Oops! Shouldn't have come this far.")
            }
            
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        weather.getWeatherByCoordinates(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //this method is called asynchronously, meaning it won't execute in the main queue.
        //all UI code needs to execute in the main queue, which is why we're wrapping the call to show simpleAlert(title: message:) in a dispatch_async() call.
        DispatchQueue.main.async {
            self.showSimpleAlert(title: "Can't determine your location", message: "The GPS and other location sevices aren't responding.")
        }
        
        print("locationManager didFailWithError: \(error)")
    }
    
    //UITextFieldDelegate and related methods
    
    //enable the 'get weather for this city' button if the city text field contains any text, otherwise diasble it.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ??  ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string).trimmed
        getCityWeatherButton.isEnabled = prospectiveText.characters.count > 0
        //print("Count: \(prospectiveText.characters.count)")
        return true
    }
    
    //pressing the clear button on the textfield (x in circle on right side of field).
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        //even though pressing the clear button clears the field, the following line is still necessary.
        textField.text = ""
        
        getCityWeatherButton.isEnabled = false
        return true
    }
    
    //pressing return button on keyboard should be like pressing the 'get weather for this city' button.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool  {
        textField.resignFirstResponder()
        getWeatherForCityButtonTapped(getCityWeatherButton)
        return true
    }
     //tapping on the view should dismiss the keyboard.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //utility methods
    func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title:"OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension String {
    //a handy method for %-encoding strings containing spaces and other characters that need to be converted for use in URLs.
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed)!
    }
    
    var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

