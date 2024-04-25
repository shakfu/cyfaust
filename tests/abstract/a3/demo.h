#ifndef DEMO_H
#define DEMO_H

#include <string>
#include <iostream>



struct Abstract {
    
    Abstract() {}
    virtual ~Abstract() {}
    
    virtual void inc(int num) = 0;
};


class Concrete : public Abstract {
public:
    Concrete() {}
    virtual ~Concrete() {}

    virtual void inc(int num)
    {
        std::cout << num + 1 << std::endl;
    }
};

void run(Abstract* instance) {
    instance->inc(100);
}


#endif /* DEMO_H */
