//
//  EventSenderTests.swift
//
//
//  Created on 27/04/2025.
//

import XCTest
@testable import Trellis

final class EventSenderTests: XCTestCase {
    
    // Test actions
    enum TestAction: Action {
        case testAction
        case anotherTestAction
    }
    
    // Test model
    actor TestModel {
        var receivedActions: [TestAction] = []
        
        func addAction(_ action: TestAction) {
            receivedActions.append(action)
        }
    }
    
    // Test service
    struct TestService: Service {
        var body: some Service {
            Store(model: TestModel.self)
                .mutate(on: TestAction.self) { model, action, _ in
                    await model.addAction(action)
                }
        }
    }
    
    func testEventSenderInitialization() async throws {
        let model = TestModel()
        let _ = try await EventSender(service: TestService().with(model: model))
        
        // Simply verifying it initializes without errors
        XCTAssertEqual(await model.receivedActions.count, 0)
    }
    
    func testEventSenderSendsAction() async throws {
        // Arrange
        let model = TestModel()
        let sender = try await EventSender(service: TestService().with(model: model))
        
        // Act
        try await sender.send(action: TestAction.testAction)
        
        // Assert
        let actions = await model.receivedActions
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(String(describing: actions[0]), String(describing: TestAction.testAction))
    }
    
    func testEventSenderSendsMultipleActions() async throws {
        // Arrange
        let model = TestModel()
        let sender = try await EventSender(service: TestService().with(model: model))
        
        // Act
        try await sender.send(action: TestAction.testAction)
        try await sender.send(action: TestAction.anotherTestAction)
        
        // Assert
        let actions = await model.receivedActions
        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(String(describing: actions[0]), String(describing: TestAction.testAction))
        XCTAssertEqual(String(describing: actions[1]), String(describing: TestAction.anotherTestAction))
    }
    
    func testEventSenderWithServiceBuilder() async throws {
        // Arrange
        let model = TestModel()
        let sender = try await EventSender {
            TestService()
                .with(model: model)
        }
        
        // Act
        try await sender.send(action: TestAction.testAction)
        
        // Assert
        let actions = await model.receivedActions
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(String(describing: actions[0]), String(describing: TestAction.testAction))
    }
    
    func testSendSingleEvent() async throws {
        // Arrange
        let model = TestModel()
        
        // Act
        try await Service.sendSingleEvent(to: TestService().with(model: model), action: TestAction.testAction)
        
        // Assert
        let actions = await model.receivedActions
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(String(describing: actions[0]), String(describing: TestAction.testAction))
    }
    
    func testSendSingleEventWithServiceBuilder() async throws {
        // Arrange
        let model = TestModel()
        
        // Act
        try await Service.sendSingleEvent({
            TestService()
                .with(model: model)
        }, action: TestAction.testAction)
        
        // Assert
        let actions = await model.receivedActions
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(String(describing: actions[0]), String(describing: TestAction.testAction))
    }
}