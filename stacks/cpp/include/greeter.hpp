#pragma once

#include <string>

class Greeter {
public:
    explicit Greeter(std::string name);
    std::string greet() const;

private:
    std::string name_;
};


