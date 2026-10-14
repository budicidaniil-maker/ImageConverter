import java.nio.file.Files;
import java.nio.file.Path;

/** IntelliJ launcher for the native C++/Objective-C++ macOS application. */
public class Main {
    public static void main(String[] args) throws Exception {
        Path project = Path.of(System.getProperty("user.dir")).toAbsolutePath();
        while (project != null && !Files.exists(project.resolve("build.command"))) {
            project = project.getParent();
        }
        if (project == null) {
            System.err.println("Не найден build.command. Откройте в IntelliJ корень проекта ImageConverter.");
            return;
        }

        Process process = new ProcessBuilder("/bin/bash", project.resolve("build.command").toString())
                .directory(project.toFile())
                .inheritIO()
                .start();
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            System.err.println("Сборка ImageConverter завершилась с ошибкой (код " + exitCode + ").");
        }
    }
}
