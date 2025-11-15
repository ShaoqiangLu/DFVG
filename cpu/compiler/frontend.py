from tvm import autotvm
from tvm.relay import expr
from tvm.relay.module import Module as _Module
from tvm.relay.build_module import BuildModule,_update_target
from tvm import relay
import argparse
import os

######################################################################
# Command line arguments
parser = argparse.ArgumentParser(description='TVM-based frontend for FPGA deployment')
parser.add_argument('--input',metavar='NAME', type=str, nargs='?', default='', help='file name(.pb/.onnx)')
parser.add_argument('--input_shape',metavar='SHAPE', type=int, nargs='+', default='', help='i.e. 1 224 224 3')
args = parser.parse_args() 
mpath = args.input
input_shape = tuple(args.input_shape)
######################################################################
# Import the graph to Relay
# -------------------------
# Import tensorflow/pytorch graph definition to relay frontend.
#
# Results:
#   sym: relay expr for given tensorflow protobuf/pytorch onnx.
#   params: params converted from tensorflow/pytorch params.
if mpath.endswith(('.onnx')):
    import onnx
    onnx_ishape = [input_shape[0],input_shape[-1]]+list(input_shape[1:-1])  
    shape_dict = {'input': tuple(onnx_ishape)}
    model = onnx.load(mpath)
    sym, params = relay.frontend.from_onnx(model, shape=shape_dict)
    print ("PyTorch onnx imported to relay frontend.")
elif mpath.endswith(('.h5')):
    import keras
    keras_ishape = [input_shape[0],input_shape[-1]]+list(input_shape[1:-1])  
    shape_dict = {'input_1': tuple(keras_ishape)}
    model = keras.models.load_model(mpath)
    sym, params = relay.frontend.from_keras(model, shape=shape_dict)
    print ("Keras h5 imported to relay frontend.")
elif mpath.endswith(('.pb')):
    import tensorflow as tf
    shape_dict = {'input': input_shape}
    with tf.gfile.FastGFile(mpath, 'rb') as f:
        graph_def = tf.GraphDef()
        graph_def.ParseFromString(f.read())
    sym, params = relay.frontend.from_tensorflow(graph_def, layout='NHWC', shape=shape_dict)
    print ("Tensorflow protobuf imported to relay frontend.")
else:
    print('[ERROR] Input model file format not supported (Tensorflow Protobuf & PyTorch ONNX)')
    exit()
    
with relay.build_config(opt_level=3):
    mod = sym
    if isinstance(mod, _Module):
        func = mod["main"]
    elif isinstance(mod, expr.Function):
        func = mod
        print(
            "Please use input parameter mod (tvm.relay.module.Module) "
            "instead of deprecated parameter func (tvm.relay.expr.Function)")
    else:
        raise ValueError("Type of input parameter mod must be tvm.relay.module.Module")
    target = _update_target('llvm')
    if isinstance(autotvm.DispatchContext.current, autotvm.FallbackContext):
        tophub_context = autotvm.tophub.context(list(target.values()))
    else:
        tophub_context = autotvm.util.EmptyContext()

    with tophub_context:
        bld_mod = BuildModule()
        mod, params = bld_mod.optimize(func, target, params)