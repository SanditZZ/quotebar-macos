//
//  BackupExportImportView.swift
//  QuoteBar — Views
//
//  The "Backup" section embedded in Settings: export a full JSON backup or a
//  CSV of just the custom quote library, and re-import a JSON backup.
//  Presentational only — everything delegates to `QuoteBackupService`.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupExportImportView: View {
    var backupService: QuoteBackupService

    @State private var showingJSONExporter = false
    @State private var showingCSVExporter = false
    @State private var showingImporter = false
    @State private var jsonExportDocument: RawDataDocument?
    @State private var csvExportDocument: RawDataDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("Export a full backup (history and your quote library) as JSON, or just your quote library as CSV. Re-importing a JSON backup restores everything without duplicating what's already here.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(AppColors.textTertiary)

            HStack {
                Button("Export JSON Backup…") {
                    jsonExportDocument = RawDataDocument(data: backupService.makeJSONExportData())
                    showingJSONExporter = true
                }
                Button("Export Quotes as CSV…") {
                    csvExportDocument = RawDataDocument(data: backupService.makeCSVExportData())
                    showingCSVExporter = true
                }
                Spacer()
                Button("Import Backup…") { showingImporter = true }
            }

            if let summary = backupService.lastOperationSummary {
                Text(summary)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if let errorMessage = backupService.errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }
        }
        .fileExporter(
            isPresented: $showingJSONExporter,
            document: jsonExportDocument,
            contentType: .json,
            defaultFilename: "QuoteBar Backup"
        ) { result in
            backupService.handleExportResult(result, formatName: "JSON")
        }
        .fileExporter(
            isPresented: $showingCSVExporter,
            document: csvExportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "QuoteBar Quotes"
        ) { result in
            backupService.handleExportResult(result, formatName: "CSV")
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            if case .success(let url) = result {
                backupService.importBackup(at: url)
            }
        }
    }
}

#Preview {
    BackupExportImportView(
        backupService: QuoteBackupService(
            quoteRepository: SwiftDataQuoteRepository(container: try! ModelContainerFactory.makeInMemory()),
            customQuoteRepository: SwiftDataCustomQuoteRepository(container: try! ModelContainerFactory.makeInMemory())
        )
    )
    .padding()
    .frame(width: 380)
}
