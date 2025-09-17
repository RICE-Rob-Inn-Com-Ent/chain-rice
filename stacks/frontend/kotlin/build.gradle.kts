plugins {
    kotlin("jvm") version "1.9.23"
    application
}

repositories { mavenCentral() }

dependencies {
    testImplementation(kotlin("test"))
}

application {
    mainClass.set("AppKt")
}

tasks.test {
    useJUnitPlatform()
}

kotlin {
    jvmToolchain(17)
}


