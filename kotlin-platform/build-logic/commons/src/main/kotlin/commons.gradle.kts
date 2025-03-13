plugins {
    id("java")
}

group = "io.github.antonmarin"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(11))
    }
}

dependencies {

    testApi(platform("org.junit:junit-bom:[5.9, 6.0)!!5.9.3"))
    testImplementation("org.junit.jupiter:junit-jupiter")
}

tasks.test {
    useJUnitPlatform()
}
