import XCTest
@testable import MSLFileManager

final class MSLFileManagerTests: XCTestCase {
    func testFileItemCreation() {
        let item = FileItem.local(url: URL(fileURLWithPath: "/tmp"))
        XCTAssertEqual(item.name, "tmp")
        XCTAssertTrue(item.isDirectory)
    }

    func testViewModeRawValues() {
        XCTAssertEqual(ViewMode.list.rawValue, "list")
        XCTAssertEqual(ViewMode.icon.rawValue, "icon")
        XCTAssertEqual(ViewMode.column.rawValue, "column")
    }

    func testSidebarItemProperties() {
        let item = SidebarItem.desktop
        XCTAssertEqual(item.displayName, "Desktop")
        XCTAssertEqual(item.iconName, "desktopcomputer")
        XCTAssertFalse(item.isRemote)
    }
}
