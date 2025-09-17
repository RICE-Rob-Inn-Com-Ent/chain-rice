#include "greeter.hpp"

Greeter::Greeter(std::string name) : name_(std::move(name)) {}

std::string Greeter::greet() const {
    return "Hello, " + name_ + "!";
}


