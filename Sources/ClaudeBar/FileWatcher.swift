// Sources/ClaudeBar/FileWatcher.swift
import Foundation

/// Watches a directory for file changes using FSEventStream.
/// Calls `onChange` on the main thread after a 2-second debounce.
final class FileWatcher {
    private let path: String
    private let onChange: @Sendable () -> Void
    private var streamRef: FSEventStreamRef?
    private var debounceWorkItem: DispatchWorkItem?

    init(path: String, onChange: @escaping @Sendable () -> Void) {
        self.path = path
        self.onChange = onChange
    }

    func start() {
        let paths = [path] as CFArray
        let selfPtr = Unmanaged.passRetained(self)

        var context = FSEventStreamContext(
            version: 0,
            info: selfPtr.toOpaque(),
            retain: nil,
            release: { ptr in
                guard let ptr else { return }
                Unmanaged<FileWatcher>.fromOpaque(ptr).release()
            },
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, clientInfo, _, _, _, _ in
            guard let info = clientInfo else { return }
            let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.scheduleChange()
        }

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagUseCFTypes
            )
        ) else { return }

        FSEventStreamScheduleWithRunLoop(
            stream,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )
        FSEventStreamStart(stream)
        streamRef = stream
    }

    func stop() {
        debounceWorkItem?.cancel()
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
    }

    deinit { stop() }

    private func scheduleChange() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [onChange] in onChange() }
        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
}
