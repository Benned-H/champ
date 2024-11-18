"""Scrape the workspace's ROS dependencies so they can be installed by Docker."""

from __future__ import annotations

from pathlib import Path

from defusedxml import ElementTree


def find_dependencies(package_xml_path: Path) -> list[str]:
    """Find the dependencies specified in the given package manifest (package.xml).

    :param package_xml_path: Path to the package.xml file for a catkin package
    :returns: List of all package dependencies specified by the package.xml
    """
    tree = ElementTree.parse(package_xml_path)
    root = tree.getroot()

    # List the XML tag names used to specify types of catkin dependencies
    depend_tag_names = [
        "depend",
        "build_depend",
        "build_export_depend",
        "exec_depend",
        "test_depend",
        "buildtool_depend",
        "doc_depend",
    ]

    depend_xpaths = [(".//" + tag) for tag in depend_tag_names]  # XPath syntax

    # Find text from the root's descendant XML elements with the relevant tag names
    return [dep.text for xpath in depend_xpaths for dep in root.findall(xpath)]


def main() -> None:
    """Scrape the ROS dependencies of all packages in the catkin workspace."""
    combined_dependencies: set[str] = set()

    # Recursively find all package.xml files in the src folder
    for package_xml in Path("../../src").rglob("package.xml"):
        found_deps = find_dependencies(package_xml)
        combined_dependencies.update(found_deps)

    # Output the dependencies as a newline-separated list
    with Path("../catkin_package_deps.txt").open("w") as deps_file:
        for dep in sorted(combined_dependencies):
            deps_file.write(f"{dep}\n")


if __name__ == "__main__":
    main()
