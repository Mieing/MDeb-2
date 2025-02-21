#import <Foundation/Foundation.h>
#include <spawn.h>
#include <sys/wait.h>

void createDirectories() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *debDirectory = @"/var/mobile/Documents/Mdeb/deb";
    NSString *dylibDirectory = @"/var/mobile/Documents/Mdeb/dylib";

    // 检查并创建deb和dylib目录
    if (![fileManager fileExistsAtPath:debDirectory]) {
        [fileManager createDirectoryAtPath:debDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    if (![fileManager fileExistsAtPath:dylibDirectory]) {
        [fileManager createDirectoryAtPath:dylibDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

void extractDylibs() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *debDirectory = @"/var/mobile/Documents/Mdeb/deb";
    NSString *dylibDirectory = @"/var/mobile/Documents/Mdeb/dylib";

    // 获取deb目录下的所有文件
    NSArray *debFiles = [fileManager contentsOfDirectoryAtPath:debDirectory error:nil];
    // 检查是否有deb文件
    if (debFiles.count == 0) {
        printf("\033[1;31mNo.deb files found in the deb folder.\033[0m\n");
        return;
    }

    for (NSString *debFile in debFiles) {
        if ([debFile.pathExtension isEqualToString:@"deb"]) {
            NSString *debFilePath = [debDirectory stringByAppendingPathComponent:debFile];
            NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

            // 创建临时目录
            [fileManager createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:nil];

            // 使用dpkg-deb解压deb文件
            char *argv[] = {"dpkg-deb", "-x", (char *)[debFilePath UTF8String], (char *)[tempDirectory UTF8String], NULL};
            posix_spawn_file_actions_t file_actions;
            posix_spawn_file_actions_init(&file_actions);
            pid_t pid;
            int status = posix_spawnp(&pid, "dpkg-deb", &file_actions, NULL, argv, NULL);
            posix_spawn_file_actions_destroy(&file_actions);

            if (status == 0) {
                if (waitpid(pid, &status, 0) == -1) {
                    perror("waitpid");
                }
            } else {
                printf("posix_spawn failed: %s\n", strerror(status));
            }

            // 移动所有.dylib文件到目标目录
            NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:tempDirectory];
            NSString *file;
            while ((file = [enumerator nextObject])) {
                if ([file.pathExtension isEqualToString:@"dylib"]) {
                    NSString *sourcePath = [tempDirectory stringByAppendingPathComponent:file];
                    NSString *destinationPath = [dylibDirectory stringByAppendingPathComponent:[file lastPathComponent]];

                    NSError *moveError = nil;
                    [fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&moveError];
                    if (moveError) {
                        printf("Failed to move %s: %s\n", [file UTF8String], [[moveError localizedDescription] UTF8String]);
                    }
                }
            }

            // 删除临时目录
            [fileManager removeItemAtPath:tempDirectory error:nil];
        }
    }

    // 提取完成后显示红色提醒
    printf("\033[1;31mExtraction completed!\033[0m\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 先创建文件夹
        createDirectories();

        if (argc > 1 && (strcmp(argv[1], "-tq") == 0 || strcmp(argv[1], "-TQ") == 0)) {
            // 解压并提取dylib文件
            extractDylibs();
        } else {
            // 浅蓝色的使用说明
            printf("\033[1;36m用法: mdeb -tq\n");
            printf("参数: -tq  将.deb 文件放置在 /var/mobile/Documents/Mdeb/deb 目录中，提取的 dylib 文件将位于 /var/mobile/Documents/Mdeb 目录中\n");
            printf("关于: mdeb v5.2.1-5 2024.8.7 - 2025.2.22 by @Mieing https://github.com/Mieing\033[0m\n");
        }
    }
    return 0;
}
