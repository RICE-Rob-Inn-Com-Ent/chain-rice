#include <iostream>
#include "greeter.hpp"

int main() {
    Greeter greeter{"World"};
    std::cout << greeter.greet() << std::endl;
    return 0;
}


