import Foundation
import CryptoKit

// Verify release artifacts using only the public key shipped in the application.
let args = CommandLine.arguments
let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: Data(base64Encoded: String(contentsOfFile: args[1], encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines))!)
let folder = URL(fileURLWithPath: args[2])
func require(_ condition: Bool, _ description: String) throws {
    if !condition { throw NSError(domain: "UpdateVerification", code: 1, userInfo: [NSLocalizedDescriptionKey: description]) }
}
final class Feed: NSObject, XMLParserDelegate {
    var enclosures: [[String: String]] = []
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "enclosure" { enclosures.append(attributeDict) }
    }
}
for arch in ["arm64", "x86_64"] {
    let url = folder.appendingPathComponent("appcast-\(arch).xml")
    let data = try Data(contentsOf: url)
    let string = String(decoding: data, as: UTF8.self)
    let pattern = #"<!-- sparkle-signatures:\s*edSignature: ([A-Za-z0-9+/=]+)\s*length: ([0-9]+)\s*-->\s*$"#
    let regex = try NSRegularExpression(pattern: pattern)
    let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string))!
    let ns = string as NSString
    let signature = Data(base64Encoded: ns.substring(with: match.range(at: 1)))!
    let length = Int(ns.substring(with: match.range(at: 2)))!
    try require(length <= data.count, "Invalid signed feed length")
    let payload = Data(data.prefix(length))
    try require(publicKey.isValidSignature(signature, for: payload), "Invalid feed signature: \(arch)")
    var damaged = payload; damaged[0] ^= 1
    try require(!publicKey.isValidSignature(signature, for: damaged), "Tampered feed was accepted")
    let reader = Feed(); let parser = XMLParser(data: payload); parser.delegate = reader
    try require(parser.parse() && reader.enclosures.count == 1, "Expected one signed enclosure")
    let item = reader.enclosures[0]
    let archiveURL = URL(string: item["url"]!)!
    let version = args[3]
    let filename = "StringNotes-\(version)-\(arch).zip"
    try require(archiveURL.absoluteString == "https://github.com/TD21forever/string-notes/releases/download/v\(version)/\(filename)", "Wrong architecture or archive URL")
    let archive = try Data(contentsOf: folder.appendingPathComponent(filename))
    let archiveSignature = Data(base64Encoded: item["sparkle:edSignature"]!)!
    try require(Int(item["length"]!) == archive.count && publicKey.isValidSignature(archiveSignature, for: archive), "Invalid archive signature")
    var corrupt = archive; corrupt[0] ^= 1
    try require(!publicKey.isValidSignature(archiveSignature, for: corrupt), "Tampered archive was accepted")
    print("PASS: \(arch) signed feed, signed archive, and tamper rejection")
}
