//
//  EventSender.swift
//
//
//  Created on 27/04/2025.
//

import Foundation

/**
 EventSender provides a streamlined way to send a single event
 without requiring a full Bootstrap setup.
 */
@MainActor
public class EventSender<T> where T: Service {
    private let service: T
    private let rootHashValue = AnyHashable(UUID())
    
    /// Initialize with a service to receive the event
    public init(service: T) async throws {
        self.service = service
        
        // Setup minimal environment
        var environment = EnvironmentValues()
        environment.send = { [unowned self] in
            try await self.send(action: $0)
        }
        
        // Inject environment into service
        try await service.inject(environment: environment, from: rootHashValue)
    }
    
    /// Send a single action to the service
    public nonisolated func send(action: any Action) async throws {
        try await service.send(action: action, from: rootHashValue)
    }
    
    /// Convenience initializer that takes a service builder closure
    public convenience init(@ServiceBuilder _ serviceBuilder: () -> T) async throws {
        try await self.init(service: serviceBuilder())
    }
}

// Convenience extension to make sending events even simpler
public extension Service {
    /// Creates an EventSender for this service and sends a single action
    @MainActor
    static func sendSingleEvent(to service: Self, action: any Action) async throws {
        let sender = try await EventSender(service: service)
        try await sender.send(action: action)
    }
    
    /// Creates an EventSender using a service builder and sends a single action
    @MainActor
    static func sendSingleEvent(@ServiceBuilder _ serviceBuilder: () -> Self, action: any Action) async throws {
        let sender = try await EventSender(serviceBuilder)
        try await sender.send(action: action)
    }
}