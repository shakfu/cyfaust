#ifndef DEMO_H
#define DEMO_H

#include <string>
#include <iostream>

template <typename T>
struct Abstract {
    
    Abstract() {}
    virtual ~Abstract() {}
    
    virtual void open(const char* label) = 0;
    virtual void inc(T num) = 0;
    virtual void close() = 0;
};

struct UI : public Abstract<int> {
    UI() {}
    virtual ~UI() {}
};

class Concrete : public UI {
public:
    Concrete() {}
    virtual ~Concrete() {}

    virtual void open(const char* label)
    {
        std::cout << "open: [" << label << "]" << std::endl;
    }
    virtual void inc(int num)
    {
        std::cout << num + 1 << std::endl;
    }
    virtual void close()
    {
        std::cout << "close()" << std::endl;
    }

};

void run(UI* instance) {
    instance->open("hello");
    instance->inc(100);
    instance->close();
}


#endif /* DEMO_H */
