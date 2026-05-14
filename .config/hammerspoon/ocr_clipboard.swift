#!/usr/bin/env swift
import AppKit
import Vision

let pb = NSPasteboard.general

var cgImage: CGImage?

if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
   let nsImage = images.first {
    var rect = NSRect(origin: .zero, size: nsImage.size)
    cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
}

if cgImage == nil {
    let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png, NSPasteboard.PasteboardType("public.jpeg")]
    for type in imageTypes {
        if let data = pb.data(forType: type), let rep = NSBitmapImageRep(data: data) {
            cgImage = rep.cgImage
            if cgImage != nil { break }
        }
    }
}

guard let image = cgImage else {
    FileHandle.standardError.write("No image found in clipboard\n".data(using: .utf8)!)
    exit(1)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

let handler = VNImageRequestHandler(cgImage: image, options: [:])

do {
    try handler.perform([request])
} catch {
    FileHandle.standardError.write("OCR failed: \(error)\n".data(using: .utf8)!)
    exit(2)
}

let observations = request.results ?? []
let text = observations
    .compactMap { $0.topCandidates(1).first?.string }
    .joined(separator: "\n")

pb.clearContents()
pb.setString(text, forType: .string)

FileHandle.standardOutput.write(text.data(using: .utf8)!)
