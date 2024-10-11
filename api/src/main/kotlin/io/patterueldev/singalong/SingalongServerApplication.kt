package io.patterueldev.singalong

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.context.annotation.ComponentScan
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories

@SpringBootApplication
@ComponentScan("io.patterueldev")
@EnableMongoRepositories(basePackages = ["io.patterueldev.mongods"])
class SingalongServerApplication
