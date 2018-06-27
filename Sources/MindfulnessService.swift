//
//  MindfulnessService.swift
//  Moment
//
//  Created by Colin Wheeler on 6/16/18.
//  Copyright © 2018 Colin Wheeler. All rights reserved.
//

/*
Copyright (c) 2018, Colin Wheeler
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation
import HealthKit

public final class MindfulService {
	public static let defaultService = MindfulService()
	private let healthStore = HKHealthStore()
	private let heatlhSampleLimit = 2147483647 // Fixme: Get rid of Magic Number
	
	private init() {}
	
	private func isHealthDataAvailable() -> Bool {
		return HKHealthStore.isHealthDataAvailable()
	}
	
	/// Errors that can be encountered with Service
	///
	/// - healthDataUnavilable: HealthKit reports data is unavailable (i.e. running on iPad)
	/// - heathKitNotAuthorized: HelathKit reports we do not have authorization
	/// - healthKitNoSamples: No Samples were returned from HealthKit
	/// - healthKitError: There was an issue in interfacing with the HealthKit System
	public enum MindfulServiceError: Error {
		case healthDataUnavilable
		case heathKitNotAuthorized
		case healthKitNoSamples
		case healthKitError
	}
	
	public enum MindfulResultType {
		case success(Int)
		case failure(MindfulServiceError)
	}
	
	public func totalMindfulnessMinutesForToday(_ completion: @escaping (MindfulResultType) -> Void) {
		guard isHealthDataAvailable() == true else {
			completion(.failure(.healthDataUnavilable))
			return
		}
		
		guard let mindfulRead = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
			completion(.failure(.healthKitError))
			return
		}
		
		self.healthStore.requestAuthorization(toShare: [mindfulRead], read: [mindfulRead]) { [weak self] (success, error) in
			
			guard let `self` = self else { return }
			
			if success == true {
				
				guard let mindfulnessSampleType = HKSampleType.categoryType(forIdentifier: .mindfulSession) else {
					DispatchQueue.main.async {
						completion(.failure(.healthKitError))
					}
					return
				}
				
				let cal = Calendar.current
				let end = Date()
				let start = cal.startOfDay(for: end)
				
				let predicate = HKSampleQuery.predicateForSamples(withStart: start,
																  end: end,
																  options: [])
				
				let query = HKSampleQuery(sampleType: mindfulnessSampleType,
										  predicate: predicate,
										  limit: self.heatlhSampleLimit,
										  sortDescriptors: nil,
										  resultsHandler: { (query, sample, error) in
											
											guard let samples = sample else {
												DispatchQueue.main.async {
													completion(.failure(.healthKitNoSamples))
												}
												return
											}
											
											guard samples.count > 0 else {
												/// technically a success, just exit early
												/// so we don't do any pointless computation
												DispatchQueue.main.async {
													completion(.success(0))
												}
												return
											}
											
											var total = 0
											
											let doubleTotal = samples.map {
												let start = $0.startDate
												let end = $0.endDate
												let elapsed = end.timeIntervalSince(start)
												return elapsed
												}.reduce(0.0, +)
											
											//convert to minutes
											total = Int(floor(doubleTotal / 60))
											
											DispatchQueue.main.async {
												completion(.success(total))
											}
				})
				
				self.healthStore.execute(query)
			}
			else {
				DispatchQueue.main.async {
					completion(.failure(.heathKitNotAuthorized))
				}
			}
		}
	}
	
	public func totalMindfulnessMinutes(completion: @escaping (MindfulResultType) -> Void) {
		guard isHealthDataAvailable() == true else {
			completion(.failure(.healthDataUnavilable))
			return
		}
		
		guard let mindfulRead = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
			completion(.failure(.healthKitError))
			return
		}
		
		self.healthStore.requestAuthorization(toShare: [mindfulRead], read: [mindfulRead]) { [weak self] (success, error) in
			
			guard let `self` = self else { return }
			
			if success == true {
				
				guard let mindfulnessSampleType = HKSampleType.categoryType(forIdentifier: .mindfulSession) else {
					DispatchQueue.main.async {
						completion(.failure(.healthKitError))
					}
					return
				}
				
				let query = HKSampleQuery(sampleType: mindfulnessSampleType,
										  predicate: nil,
										  limit: self.heatlhSampleLimit,
										  sortDescriptors: nil,
										  resultsHandler: { (query, sample, error) in
											
											guard let samples = sample else {
												DispatchQueue.main.async {
													completion(.failure(.healthKitNoSamples))
												}
												return
											}
											
											guard samples.count > 0 else {
												/// technically a success, just exit early
												/// so we don't do any pointless computation
												DispatchQueue.main.async {
													completion(.success(0))
												}
												return
											}
											
											var total = 0
											
											let doubleTotal = samples.map {
												let start = $0.startDate
												let end = $0.endDate
												let elapsed = end.timeIntervalSince(start)
												return elapsed
											}.reduce(0.0, +)
											
											//convert to minutes
											total = Int(floor(doubleTotal / 60))
											
											DispatchQueue.main.async {
												completion(.success(total))
											}
				})
				
				self.healthStore.execute(query)
			}
			else {
				DispatchQueue.main.async {
					completion(.failure(.heathKitNotAuthorized))
				}
			}
		}
	}
}
