plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.spring)
    alias(libs.plugins.spring.boot)
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
    implementation(libs.spring.boot.web)
    implementation(libs.spring.boot.data.mongodb)
    implementation(libs.spring.boot.security)
    implementation(libs.springdoc.openapi.ui)
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.netty.socketio)
    implementation(libs.openapi.generator)
    implementation(libs.jackson.kotlin)
    testRuntimeOnly(libs.junit.platform.launcher)
    testImplementation(libs.spring.boot.test)
    testImplementation(libs.kotlin.test.junit)
    implementation(projects.mongoDs)
    implementation(projects.commonds)
    implementation(projects.sessionds)
    implementation(projects.songidentifierds)
    implementation(projects.songbookds)
    implementation(projects.reservationds)
    implementation(projects.adminds)
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
