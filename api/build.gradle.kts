plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.kotlinSpring)
    alias(libs.plugins.springBoot)
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
    implementation(libs.springBootWebSocket)
    implementation(libs.springBootSecurity)
    implementation(libs.jacksonKotlin)
    implementation(libs.kotlinReflect)
    testRuntimeOnly(libs.junitPlatformLauncher)
    implementation(libs.kotlinxCoroutinesReactor)
    implementation(libs.springBootWebflux)
    implementation(libs.openAIClient)
    implementation(libs.ktorClientCIO)
    testImplementation(libs.springBootStarterTest)
    testImplementation(libs.kotlinTestJunit5)
    implementation(projects.shared)
    implementation(projects.sessionroom)
    implementation(projects.sessionroomds)
    implementation(projects.songidentifier)
    implementation(projects.songidentifierds)
    implementation(projects.songbook)
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