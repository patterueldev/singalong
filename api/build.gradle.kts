plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.kotlinSpring)
    alias(libs.plugins.springBoot)
    alias(libs.plugins.ktlint)
}

dependencyLocking {
    lockAllConfigurations()
}

group = "io.patterueldev"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

dependencies {
    implementation(libs.springBootWeb)
    implementation(libs.springBootDataMongo)
    implementation(libs.springBootSecurity)
//    implementation(libs.springBootWebSocket) // TODO: will be used in the future
    testRuntimeOnly(libs.junitPlatformLauncher)
    testImplementation(libs.springBootStarterTest)
    testImplementation(libs.kotlinTestJunit5)
    implementation(projects.mongoDs)
    implementation(projects.commonds)
    implementation(projects.sessionds)
    implementation(projects.songidentifierds)
    implementation(projects.songbookds)
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
    systemProperty("spring.profiles.active", "test")
}
