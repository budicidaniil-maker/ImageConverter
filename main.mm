#import <Cocoa/Cocoa.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface DropView : NSView
@property(nonatomic, copy) void (^fileDropped)(NSURL *url);
@property(nonatomic, copy) NSString *message;
@property(nonatomic, strong) NSImage *preview;
@end

@implementation DropView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.message = @"Перетащите изображение сюда\nили нажмите «Выбрать файл»";
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    }
    return self;
}
- (void)drawRect:(NSRect)dirtyRect {
    NSRect imageRect = NSZeroRect;
    NSRect frameRect = NSInsetRect(self.bounds, 2, 2);
    if (self.preview) {
        NSSize imageSize = self.preview.size;
        if (imageSize.width > 0 && imageSize.height > 0) {
            CGFloat scale = MIN(1.0, MIN((NSWidth(self.bounds)-36)/imageSize.width,
                                         (NSHeight(self.bounds)-36)/imageSize.height));
            NSSize fitted = NSMakeSize(imageSize.width * scale, imageSize.height * scale);
            imageRect = NSMakeRect(NSMidX(self.bounds)-fitted.width/2,
                                   NSMidY(self.bounds)-fitted.height/2,
                                   fitted.width, fitted.height);
            frameRect = NSInsetRect(imageRect, -12, -12);
        }
    }
    [[NSColor colorWithRed:.97 green:.97 blue:.99 alpha:1] setFill];
    NSBezierPath *box = [NSBezierPath bezierPathWithRoundedRect:frameRect xRadius:12 yRadius:12];
    [box fill];
    [[NSColor colorWithCalibratedRed:.40 green:.42 blue:.58 alpha:1] setStroke];
    CGFloat dash[] = {6, 4};
    [box setLineDash:dash count:2 phase:0];
    [box stroke];
    if (self.preview && !NSIsEmptyRect(imageRect)) {
        [self.preview drawInRect:imageRect
                        fromRect:NSZeroRect
                       operation:NSCompositingOperationSourceOver
                        fraction:1.0
                  respectFlipped:YES
                           hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
        return;
    }
    NSDictionary *attrs = @{NSFontAttributeName:[NSFont systemFontOfSize:15], NSForegroundColorAttributeName:[NSColor secondaryLabelColor], NSParagraphStyleAttributeName:({ NSMutableParagraphStyle *p = [NSMutableParagraphStyle new]; p.alignment = NSTextAlignmentCenter; p; })};
    NSSize size = [self.message sizeWithAttributes:attrs];
    [self.message drawInRect:NSMakeRect(15, (NSMaxY(self.bounds)-size.height)/2, NSWidth(self.bounds)-30, size.height) withAttributes:attrs];
}
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender { return NSDragOperationCopy; }
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSURL *url = [NSURL URLFromPasteboard:sender.draggingPasteboard];
    if (url && self.fileDropped) self.fileDropped(url);
    return url != nil;
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) DropView *dropView;
@property(nonatomic, strong) NSPopUpButton *formatMenu;
@property(nonatomic, strong) NSTextField *nameField;
@property(nonatomic, strong) NSTextField *folderField;
@property(nonatomic, strong) NSTextField *status;
@property(nonatomic, strong) NSURL *inputURL;
@property(nonatomic, strong) NSArray<NSDictionary *> *formats;
@end

@implementation AppDelegate
- (NSTextField *)label:(NSString *)text y:(CGFloat)y {
    NSTextField *field = [NSTextField labelWithString:text];
    field.frame = NSMakeRect(30, y, 500, 20);
    [self.window.contentView addSubview:field];
    return field;
}
- (NSButton *)button:(NSString *)title y:(CGFloat)y action:(SEL)action width:(CGFloat)width x:(CGFloat)x {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action];
    button.frame = NSMakeRect(x, y, width, 34);
    button.bezelStyle = NSBezelStyleRounded;
    [self.window.contentView addSubview:button];
    return button;
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 560, 590)
        styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"ImageConverter — конвертер изображений";
    [self.window center];
    NSView *content = self.window.contentView;
    NSTextField *title = [NSTextField labelWithString:@"Конвертер изображений"];
    title.font = [NSFont boldSystemFontOfSize:25]; title.frame = NSMakeRect(30, 535, 500, 32); [content addSubview:title];
    NSTextField *subtitle = [NSTextField labelWithString:@"Преобразуйте изображение в формат, поддерживаемый macOS"];
    subtitle.frame = NSMakeRect(30, 510, 500, 20); [content addSubview:subtitle];

    self.dropView = [[DropView alloc] initWithFrame:NSMakeRect(30, 365, 500, 125)];
    __weak AppDelegate *weakSelf = self;
    self.dropView.fileDropped = ^(NSURL *url) { [weakSelf setInput:url]; };
    [content addSubview:self.dropView];
    [self button:@"Выбрать файл…" y:315 action:@selector(chooseFile:) width:150 x:30];

    [self label:@"Формат результата" y:278];
    self.formatMenu = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(30, 240, 500, 32) pullsDown:NO];
    [content addSubview:self.formatMenu];
    [self loadFormats];

    [self label:@"Имя выходного файла" y:205];
    self.nameField = [NSTextField textFieldWithString:@""];
    self.nameField.placeholderString = @"Например: отпуск";
    self.nameField.frame = NSMakeRect(30, 168, 500, 30); [content addSubview:self.nameField];

    [self label:@"Папка сохранения" y:133];
    self.folderField = [NSTextField textFieldWithString:[NSHomeDirectory() stringByAppendingPathComponent:@"Pictures"]];
    self.folderField.frame = NSMakeRect(30, 95, 390, 30); [content addSubview:self.folderField];
    [self button:@"Папка…" y:93 action:@selector(chooseFolder:) width:100 x:430];

    NSButton *convert = [self button:@"Конвертировать" y:43 action:@selector(convert:) width:500 x:30];
    convert.keyEquivalent = @"\r";
    self.status = [NSTextField labelWithString:@"Результат будет сохранён в выбранную папку."];
    self.status.frame = NSMakeRect(30, 12, 500, 24); [content addSubview:self.status];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}
- (void)loadFormats {
    NSMutableArray *found = [NSMutableArray array];
    for (NSString *identifier in (__bridge_transfer NSArray *)CGImageDestinationCopyTypeIdentifiers()) {
        UTType *type = [UTType typeWithIdentifier:identifier];
        NSString *ext = type.preferredFilenameExtension;
        if (!ext.length) continue;
        [found addObject:@{ @"name": ext.uppercaseString, @"uti": identifier, @"ext": ext.lowercaseString }];
    }
    self.formats = [found sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]]; }];
    for (NSDictionary *item in self.formats) [self.formatMenu addItemWithTitle:item[@"name"]];
    NSInteger jpeg = [self.formatMenu indexOfItemWithTitle:@"JPG"];
    if (jpeg < 0) jpeg = [self.formatMenu indexOfItemWithTitle:@"JPEG"];
    if (jpeg >= 0) [self.formatMenu selectItemAtIndex:jpeg];
}
- (void)setInput:(NSURL *)url {
    if (!url.isFileURL) return;
    self.inputURL = url;
    self.dropView.message = [NSString stringWithFormat:@"Выбран файл:\n%@", url.lastPathComponent];
    self.dropView.preview = [[NSImage alloc] initWithContentsOfURL:url];
    [self.dropView setNeedsDisplay:YES];
    if (!self.nameField.stringValue.length) self.nameField.stringValue = url.lastPathComponent.stringByDeletingPathExtension;
    self.status.stringValue = @"Готово к конвертации.";
}
- (void)chooseFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES; panel.canChooseDirectories = NO; panel.allowsMultipleSelection = NO;
    if ([panel runModal] == NSModalResponseOK) [self setInput:panel.URL];
}
- (void)chooseFolder:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = NO; panel.canChooseDirectories = YES; panel.allowsMultipleSelection = NO;
    if ([panel runModal] == NSModalResponseOK) self.folderField.stringValue = panel.URL.path;
}
- (void)convert:(id)sender {
    if (!self.inputURL) { [self alert:@"Сначала выберите или перетащите изображение." title:@"Нет файла"]; return; }
    NSDictionary *selected = self.formats[(NSUInteger)self.formatMenu.indexOfSelectedItem];
    NSString *base = [self.nameField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!base.length) base = self.inputURL.lastPathComponent.stringByDeletingPathExtension;
    base = [base stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSURL *destination = [NSURL fileURLWithPath:[[self.folderField.stringValue stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", base, selected[@"ext"]]]];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)self.inputURL, NULL);
    if (!source || CGImageSourceGetCount(source) == 0) {
        if (source) CFRelease(source);
        [self alert:@"Файл не удалось прочитать как изображение." title:@"Ошибка"];
        return;
    }
    CGImageDestinationRef output = CGImageDestinationCreateWithURL((__bridge CFURLRef)destination, (__bridge CFStringRef)selected[@"uti"], 1, NULL);
    if (output) CGImageDestinationAddImageFromSource(output, source, 0, NULL);
    BOOL ok = output && CGImageDestinationFinalize(output);
    if (output) CFRelease(output);
    CFRelease(source);
    if (!ok) { [self alert:@"macOS не смогла сохранить изображение в выбранном формате." title:@"Ошибка конвертации"]; return; }
    self.status.stringValue = [NSString stringWithFormat:@"Готово: %@", destination.path];
    [self alert:[NSString stringWithFormat:@"Изображение сохранено:\n%@", destination.path] title:@"Готово"];
}
- (void)alert:(NSString *)message title:(NSString *)title {
    NSAlert *alert = [NSAlert new]; alert.messageText = title; alert.informativeText = message; [alert runModal];
}
@end

int main() {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app run];
        return 0;
    }
}
