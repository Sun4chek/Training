//
//  TrackerTests.swift
//  TrackerTests
//
//  Created by Волошин Александр on 8/27/25.
//
import XCTest
import SnapshotTesting
@testable import Tracker

final class MainViewControllerSnapshotTests: XCTestCase {

    var tabBarController: TabBarController!
    var mainViewController: MainViewController!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        
        tabBarController = TabBarController()
        let navController = tabBarController.viewControllers?.first as? UINavigationController
        mainViewController = navController?.viewControllers.first as? MainViewController
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        tabBarController = nil
        mainViewController = nil
        super.tearDown()
    }

    private func prepareForSnapshot() {
        tabBarController.loadViewIfNeeded()
        mainViewController.loadViewIfNeeded()
        mainViewController.view.setNeedsLayout()
        mainViewController.view.layoutIfNeeded()

        tabBarController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844))

        RunLoop.main.run(until: Date())
    }

    func testMainViewControllerLightTheme() {
        //isRecording = true
        tabBarController.overrideUserInterfaceStyle = .light
        prepareForSnapshot()
        assertSnapshot(
            of: tabBarController,
            as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .light)),
            named: "MainViewController_Light"
        )
    }

    func testMainViewControllerDarkTheme() {
        //isRecording = true
        tabBarController.overrideUserInterfaceStyle = .dark
        prepareForSnapshot()
        assertSnapshot(
            of: tabBarController,
            as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "MainViewController_Dark"
        )
    }
}
