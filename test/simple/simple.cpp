#include <node.h>
#include <nan.h>

void Method(const Nan::FunctionCallbackInfo<v8::Value> &info) {
    info.GetReturnValue().Set(Nan::New("world").ToLocalChecked());
}

void RegisterModule(v8::Local<v8::Object> exports) {
    exports->Set(Nan::New("hello").ToLocalChecked(),
                 Nan::New<v8::FunctionTemplate>(Method)->GetFunction());
}

NODE_MODULE(MODULE_NAME, RegisterModule)
