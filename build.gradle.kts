plugins {
    alias(libs.plugins.kotlinJvm).apply(false)
    alias(libs.plugins.kotlinSpring).apply(false)
    alias(libs.plugins.springBoot).apply(false)
    alias(libs.plugins.springDependencyManagement).apply(false)
    alias(libs.plugins.ktlint)
}
