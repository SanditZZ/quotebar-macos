//
//  RawDataDocument.swift
//  QuoteBar — Actions
//
//  A `FileDocument` that just carries pre-serialized bytes out to disk. Used
//  for both the JSON and CSV backup exports — the actual serialization
//  (`QuoteBackupSerializer`, `CustomQuoteCSVFormatter`) already happened
//  before this is constructed, so this type has nothing format-specific to
//  do. Read support is required by the `FileDocument` protocol even though
//  this app never re-opens an exported file through `.fileExporter`'s own
//  document round-trip — re-import goes through `.fileImporter` instead,
//  same as the existing custom-quote import flow.
//

import SwiftUI
import UniformTypeIdentifiers

struct RawDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileContents: data)
    }
}
