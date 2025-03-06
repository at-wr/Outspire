// From GitHub Gists: rileytestut/ExportIPA.swift
// https://gist.github.com/rileytestut/5b3ede1cfeaba47cea9e6c1c8c114e4e

import SwiftUI
import UniformTypeIdentifiers

extension UTType
{
    static let ipa = UTType(filenameExtension: "ipa")!
}

struct IPAFile: FileDocument
{
    private var _file: Any
    
    var file: FileWrapper {
        return _file as! FileWrapper
    }
    
    init(file: FileWrapper) {
        self._file = file
    }
    
    static var readableContentTypes: [UTType] { [.ipa] }
    static var writableContentTypes: [UTType] { [.ipa] }
    
    init(ipaURL: URL) throws
    {
        self._file = try FileWrapper(url: ipaURL, options: .immediate)
    }
    
    init(configuration: ReadConfiguration) throws 
    {
        self._file = configuration.file
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper 
    {
        return self.file
    }
}

struct ExportView: View 
{
    @State 
    private var isExporting = false
    
    @State
    private var ipaFile: IPAFile?
    
    var body: some View {
        VStack(spacing: 25) {
            Button(action: export) { 
                Label("Export IPA", systemImage: "square.and.arrow.up")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
            }
        }
        .fileExporter(isPresented: self.$isExporting, document: self.ipaFile, contentType: .ipa) { result in
            print("Exported IPA:", result)
        }
    }
    
    private func export()
    {
        Task { @MainActor in            
            do
            {
                let ipaPath = try await exportIPA()
                let ipaURL = URL(fileURLWithPath: ipaPath)
                
                self.ipaFile = try IPAFile(ipaURL: ipaURL)
                self.isExporting = true
            }
            catch
            {
                print("Could not export .ipa:", error)
            }
        }
    }
}
