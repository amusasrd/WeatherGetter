//
//  WeatherGetter.swift
//  iWeather
//
//  Created by Ahmed Musa on 29/12/16.
//  Copyright © 2016 Moses Apps. All rights reserved.
//

import Foundation

/* MARK: WeatherGetterDelegate
 weathergetter should be used by a class or struct, and that class or struct should adopt this protocol and register itself as the delegate.
 the delegate's didgetweather method is called if the weather data was acquired from openweathermap.org and successfully converted from JSON into a swift dictionary.
 the delegate's didnotgetweather is called if either:
 the weather was not acquired by from openweathermap.org, or 
 the received data could not be converted from json into a swift dictionary.
*/

protocol WeatherGetterDelegate {
    func didGetWeather(_ weather: Weather)
    func didNotGetWeather(_ error: NSError)
}

class WeatherGetter {
    
    fileprivate let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    fileprivate let openWeatherMapAPIKey = "d3f456940cf3d89080b3382a06bf7197"
    
    fileprivate var delegate: WeatherGetterDelegate
    
    init(delegate: WeatherGetterDelegate) {
        self.delegate = delegate
    }
    
    func getWeatherByCity(_ city: String) {
        let weatherRequestURL = URL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)")!
        getWeather(weatherRequestURL)
    }
    
    func getWeatherByCoordinates(latitude: Double, longitude: Double) {
        let weatherRequestURL = URL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&lat=\(latitude)&lon=\(longitude)")!
        getWeather(weatherRequestURL)
    }
    
    fileprivate func getWeather(_ weatherRequestURL: URL) {
        
        //this is a pretty simple networking task so the shared session will do.
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 3
        
        //the data task retrieves the data.
        let dataTask = session.dataTask(with: weatherRequestURL, completionHandler: {
            
            (data: Data?, response: URLResponse?, error: NSError?) in
            
            //(data, response, error) -> Void in
            
            if let networkError = error {
                //case 1: error, error occurred while attempting to retrieve data from the server.
                self.delegate.didNotGetWeather(networkError)
            }
            else {
                //case 2: success! got data from server.
                do {
                    //try to convert data into swift dictionary.
                    let weatherData = try JSONSerialization.jsonObject( with: data!, options: .mutableContainers) as! [String: AnyObject]
                    
                    // If we made it to this point, we've successfully converted JSON-formatted weather data into a Swift dictionary. Let's now use that dictionary to initialize a Weather struct.

                    let weather = Weather(weatherData: weatherData)
                    
                    //now we have a weather struct; lets notify view controller, which will use it to display weather to user.
                    
                    self.delegate.didGetWeather(weather)
                }
                catch let jsonError as NSError {
                    //an error occurred while trying to convert the data into a swift dictionary.
                    self.delegate.didNotGetWeather(jsonError)
                }
            }
        } as! (Data?, URLResponse?, Error?) -> Void) 
        
        //data is set up....launch it!
        dataTask.resume()
        
    }
}

        /* all of the below is for displaying on debug console. more needed though as some was used for app.
        // ** 1 **
        //this is a pretty simple networking task so the shared session will do.
        let session = NSURLSession.sharedSession()
        
        // ** 2 **
        let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)")!
        
        // ** 3 **
        //the data task retrieves the data.
        let dataTask = session.dataTaskWithURL(weatherRequestURL) {
            
            (data: NSData?, response: NSURLResponse?, error: NSError?) in
            
            //(data, response, error) -> Void in
            
            // ** 4 **
            if let error = error {
                //case 1: Error
                //we got some kind of error while trying to get data from the server.
                print("Error:\n\(error)")
            }
                
            // ** 5 **
            else {
                //case 2: Success
                //we got a response from the server!
                do {
                    //try to convert the data into a swift dictionary
                    let weather = try NSJSONSerialization.JSONObjectWithData( data!, options: .MutableContainers) as! [String: AnyObject]
                    
                    //if we made it this far, we've successfully converted the JSON-formatted data into a swift dictionary.
                    //lets print its contents to the debug console.
                    print("Date and time: \(weather["dt"]!)")
                    print("City: \(weather["name"]!)")
                    
                    print("Longitude: \(weather["coord"]!["long"]!!)")
                    print("Latitude: \(weather["coord"]!["lat"]!!)")
                    
                    print("Weather ID: \(weather["weather"]![0]!["id"]!!)")
                    print("Weather Main: \(weather["weather"]![0]!["main"]!!)")
                    print("Weather description: \(weather["weather"]![0]!["description"]!!)")
                    print("Weather icon ID: \(weather["weather"]![0]!["icon"]!!)")
                    
                    print("Temperature: \(weather["main"]!["temp"]!!)")
                    print("Humidity: \(weather["main"]!["humidity"]!!)")
                    print("Pressure: \(weather["main"]!["pressure"]!!)")
                    
                    print("Cloud Cover: \(weather["clouds"]!["all"]!!)")
                    
                    print("Wind Direction: \(weather["wind"]!["deg"]!!) degrees")
                    print("Wind speed: \(weather["wind"]!["speed"]!!)")
                    
                    print("Country: \(weather["sys"]!["country"]!!)")
                    print("Sunrise: \(weather["sys"]!["sunrise"]!!)")
                    print("Sunset: \(weather["sys"]!["sunset"]!!)")
                }
                
                catch let jsonError as NSError {
                    //an error occurred while trying to convert the data into a swift dictionary.
                    print("JSON error description: \(jsonError.description)")
                }
            
                 print("Raw data:\n\(data!)\n")
                let dataString = String(data: data!, encoding: NSUTF8StringEncoding)
                print( "Human-readable data:\n\(dataString!)")
            }
        }
        
        // ** 6 **
        //the data is set up... launch it!
        dataTask.resume()
    }
} 
*/
