// interpreter class

#include <stdarg.h>
#include <sys/stat.h>
#include <libgen.h>

#include "ZajalInterpreter.h"
#include "ruby/encoding.h"
#include "node.h"

// generated by Makefile, defines locations of ruby libraries
#include "config.h"

#include "ofRendererCollection.h"

extern ofRendererCollection renderer;

VALUE zj_button_to_symbol(int button) {
  if(button == 0)
    return SYM("left");
  else if(button == 1)
    return SYM("middle");
  else if(button == 2)
    return SYM("right");
  else
    rb_bug("Received unsupported button `%d'on mouseDragged! Bailing out!", button);
}

ZajalInterpreter::ZajalInterpreter() {
  // start ruby/zajal
  ruby_init();
  zajal_init();
  
  keyIsPressed = false;
  mouseIsPressed = false;
  
  state = INTERPRETER_NO_SKETCH;
  scriptModifiedTime = 0;
  
  scriptName = NULL;
  nextUpdate = SCRIPT_UPDATE_FREQUENCY;
  
  INTERNAL_SET(zj_mApp, current_code, rb_str_new2(""));
  INTERNAL_SET(zj_mApp, verbose, Qfalse);
  
  initialWidth = DEFAULT_INITIAL_WIDTH;
  initialHeight = DEFAULT_INITIAL_HEIGHT;
}

InterpreterState ZajalInterpreter::getState() {
  return state;
}

void ZajalInterpreter::printVersion() {
  char* zj_version = RSTRING_PTR(rb_const_get(rb_cObject, rb_intern("ZAJAL_VERSION")));
  char* zj_hash = RSTRING_PTR(rb_const_get(rb_cObject, rb_intern("ZAJAL_HASH")));
  char* zj_branch = RSTRING_PTR(rb_const_get(rb_cObject, rb_intern("ZAJAL_BRANCH")));
  
  char* of_version = RSTRING_PTR(rb_const_get(rb_cObject, rb_intern("OF_VERSION")));
  char* rb_version = RSTRING_PTR(rb_const_get(rb_cObject, rb_intern("RUBY_VERSION")));
  
  if(strcmp(zj_branch, "master") == 0)
    printf("zajal %s-%s\n", zj_version, zj_hash);
  else
    printf("zajal %s-%s [%s]\n", zj_version, zj_hash, zj_branch);
  
  printf("openFrameworks %s\nruby %s\n", of_version, rb_version);
}

void ZajalInterpreter::run() {
  state = INTERPRETER_RUNNING;
  ofSetupOpenGL(initialWidth, initialHeight, OF_WINDOW);
  reloadScript();
  ofRunApp(this);
}

void ZajalInterpreter::run(ofAppBaseWindow* window) {
  state = INTERPRETER_RUNNING;
  ofSetupOpenGL(window, initialWidth, initialHeight, OF_WINDOW);
  reloadScript();
  ofRunApp(this);
}

void ZajalInterpreter::appendLoadPath(char* path) {
  char* resolved_path = realpath(path, NULL);
  if(resolved_path) {
    rb_ary_push(rb_gv_get("$:"), rb_str_new2(resolved_path));
    
  } else {
    fprintf(stderr, "WARNING: `%s' not a valid path. Not adding to load path.\n", path);
    
  }
  
  free(resolved_path);
}

void ZajalInterpreter::setInitialWidth(int w) {
  rb_ary_store(rb_hash_aref(INTERNAL_GET(zj_mEvents, initial_defaults), SYM("size")), 0, INT2FIX(w));
  initialWidth = w;
}

void ZajalInterpreter::setInitialHeight(int h) {
  rb_ary_store(rb_hash_aref(INTERNAL_GET(zj_mEvents, initial_defaults), SYM("size")), 1, INT2FIX(h));
  initialHeight = h;
}

//--------------------------------------------------------------
void ZajalInterpreter::setup() {
  ofSetDefaultRenderer(&renderer);
  
  if(state == INTERPRETER_RUNNING) {
    INTERNAL_SET(zj_mEvents, current_event, SYM("setup"));
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, setup_proc), 0);
    if(ruby_error) state = INTERPRETER_ERROR;
  }
}

//--------------------------------------------------------------
void ZajalInterpreter::update() {
  if(state == INTERPRETER_RUNNING) {
    INTERNAL_SET(zj_mEvents, current_event, SYM("update"));
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, defaults_proc), 0);
    
    VALUE prehooks_ary = INTERNAL_GET(zj_mEvents, update_prehooks);
    VALUE* prehooks_ptr = RARRAY_PTR(prehooks_ary);
    int prehooks_len = RARRAY_LEN(prehooks_ary);
    
    for(int i = 0; i < prehooks_len; i++) {
      zj_safe_proc_call(prehooks_ptr[i], 0);
    }
    
    // if no error exists, run user update method, catch runtime errors
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, update_proc), 0);
    if(ruby_error) {state = INTERPRETER_ERROR; return; }
    
    VALUE posthooks_ary = INTERNAL_GET(zj_mEvents, update_posthooks);
    VALUE* posthooks_ptr = RARRAY_PTR(posthooks_ary);
    int posthooks_len = RARRAY_LEN(posthooks_ary);
    
    for(int i = 0; i < posthooks_len; i++){
      zj_safe_proc_call(posthooks_ptr[i], 0);
    }
    
  }
}

//--------------------------------------------------------------
void ZajalInterpreter::draw() {
  VALUE error_message, last_error, backtrace;
  VALUE* backtrace_ptr;
  char* error_message_ptr, *error_class;
  long backtrace_length;
  
  switch(state) {
    case INTERPRETER_ERROR:
      INTERNAL_SET(zj_mEvents, current_event, SYM("draw"));
      // TODO stop all playing videos
      
      error_message = zj_safe_funcall(rb_cObject, rb_intern("process_error"), 0);
      if(ruby_error) {
        error_message_ptr = RSTRING_PTR(rb_obj_as_string(rb_gv_get("$!")));
      } else {
        error_message_ptr = RSTRING_PTR(error_message);
      }
      
      if(RTEST(INTERNAL_GET(zj_mApp, verbose))) {
        // http://metaeditor.sourceforge.net/embed/
        last_error = rb_gv_get("$!");
        error_class = RSTRING_PTR(rb_class_path(CLASS_OF(last_error)));
        error_message_ptr = RSTRING_PTR(rb_obj_as_string(last_error));
        logConsoleText("$stderr", "class   = %s\n", error_class); 
        logConsoleText("$stderr", "message = %s\n", error_message_ptr); 
        
        logConsoleText("$stderr", "backtrace = \n");
        backtrace = rb_attr_get(last_error, rb_intern("bt"));
        backtrace_length = RARRAY_LEN(backtrace);
        backtrace_ptr = RARRAY_PTR(backtrace);
        for(int i=0; i<backtrace_length; i++)
          logConsoleText("$stderr", "\tfrom %s\n", RSTRING_PTR(backtrace_ptr[i]));
      }
      
      // an error exists, draw error screen
      ofSetColor(255, 255, 255, 255);
      //lastErrorImage.draw(0, 0);
      // TODO apply filters to lastErrorImage instead of drawing a rect
      //ofEnableAlphaBlending();
      ofFill();
      ofSetColor(255, 255, 255, 128);
      ofRect(0, 0, ofGetWidth(), ofGetHeight());
      ofSetColor(255, 255, 255, 255);
      ofRect(0, ofGetHeight()/2-25, ofGetWidth(), 35);
      ofSetColor(0, 0, 0, 255);
      ofDrawBitmapString(error_message_ptr, 10, ofGetHeight()/2-10);
      zj_safe_proc_call(INTERNAL_GET(zj_mEvents, defaults_proc), 0);
      break;
      
    case INTERPRETER_RUNNING:
      INTERNAL_SET(zj_mEvents, current_event, SYM("draw"));
      VALUE prehooks_ary = INTERNAL_GET(zj_mEvents, draw_prehooks);
      VALUE* prehooks_ptr = RARRAY_PTR(prehooks_ary);
      int prehooks_len = RARRAY_LEN(prehooks_ary);
    
      for(int i = 0; i < prehooks_len; i++) {
        zj_safe_proc_call(prehooks_ptr[i], 0);
      }
    
      // no error exists, draw next frame of user code, catch runtime errors
      zj_graphics_reset_frame();
      zj_safe_proc_call(INTERNAL_GET(zj_mEvents, draw_proc), 0);
      if(ruby_error) state = INTERPRETER_ERROR;
      
      VALUE posthooks_ary = INTERNAL_GET(zj_mEvents, draw_posthooks);
      VALUE* posthooks_ptr = RARRAY_PTR(posthooks_ary);
      int posthooks_len = RARRAY_LEN(posthooks_ary);
    
      for(int i = 0; i < posthooks_len; i++){
        zj_safe_proc_call(posthooks_ptr[i], 0);
        if(ruby_error) state = INTERPRETER_ERROR;
      } 
      
      // fake continious mouse press
      if(mouseIsPressed)
        zj_safe_proc_call(INTERNAL_GET(zj_mEvents, mouse_pressed_proc), 3, lastMouseX, lastMouseY, lastMouseButton);
      if(ruby_error) state = INTERPRETER_ERROR;
      
      break;
      
  }
  
  // try to update script at end of setup-update-draw loop
  if(nextUpdate-- == 0) updateCurrentScript();
}

void ZajalInterpreter::updateCurrentScript() {
  VALUE watched_files_ary = INTERNAL_GET(zj_mZajal, watched_files);
  VALUE* watched_files_ptr = RARRAY_PTR(watched_files_ary);
  int watched_files_len = RARRAY_LEN(watched_files_ary);

  for (int i = 0; i < watched_files_len; ++i) {
    char* filePath = StringValuePtr(watched_files_ptr[i]);

    if(filePath) {
      struct stat attrib;
      if(stat(filePath, &attrib)) {
        fprintf(stderr, "FATAL ERROR: Could not access `%s'. Zajal must quit.\n", filePath);
        fprintf(stderr, "  The file is either missing or otherwise inaccessible. Check the file name\n");
        fprintf(stderr, "  or the file's permissions.\n");
        ::exit(1);
        
      } else {
        if(attrib.st_mtimespec.tv_sec > scriptModifiedTime) {
          logConsoleText("$stdout", "Updating %s in place...\n", filePath);
          scriptModifiedTime = attrib.st_mtimespec.tv_sec;
          if(i > 0) rb_funcall(rb_mKernel, rb_intern("load"), 1, rb_str_new2(filePath));
          reloadScript();
        }
        
      }
    }
  }
  
  nextUpdate = SCRIPT_UPDATE_FREQUENCY;
}

char* ZajalInterpreter::getCurrentScriptPath() {
  return scriptName;
}

//--------------------------------------------------------------
void ZajalInterpreter::exit() {
  if(state == INTERPRETER_RUNNING) {
    VALUE prehooks_ary = INTERNAL_GET(zj_mEvents, exit_prehooks);
    VALUE* prehooks_ptr = RARRAY_PTR(prehooks_ary);
    int prehooks_len = RARRAY_LEN(prehooks_ary);
    
    for(int i = 0; i < prehooks_len; i++) {
      zj_safe_proc_call(prehooks_ptr[i], 0);
    }

    // TODO convert key into symbols
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, exit_proc), 0);
    if(ruby_error) state = INTERPRETER_ERROR;
  }

    VALUE posthooks_ary = INTERNAL_GET(zj_mEvents, exit_posthooks);
    VALUE* posthooks_ptr = RARRAY_PTR(posthooks_ary);
    int posthooks_len = RARRAY_LEN(posthooks_ary);
    
    for(int i = 0; i < posthooks_len; i++) {
      zj_safe_proc_call(posthooks_ptr[i], 0);
    }

}

//--------------------------------------------------------------
void ZajalInterpreter::keyPressed  (int key) {
  if(state == INTERPRETER_RUNNING) {
    VALUE zj_cKeyEvent = rb_const_get(rb_cObject, rb_intern("KeyEvent"));
    VALUE keyEvent = zj_safe_funcall(zj_cKeyEvent, rb_intern("new"), 1, INT2FIX(key));
    if(ruby_error) state = INTERPRETER_ERROR;
    
    if(keyIsPressed) {
      zj_safe_proc_call(INTERNAL_GET(zj_mEvents, key_pressed_proc), 1, keyEvent);
      
    } else {
      zj_safe_proc_call(INTERNAL_GET(zj_mEvents, key_down_proc), 1, keyEvent);
      keyIsPressed = true;
    }
    
    if(ruby_error) state = INTERPRETER_ERROR;
  }
}

//--------------------------------------------------------------
void ZajalInterpreter::keyReleased  (int key) {
  if(state == INTERPRETER_RUNNING) {
    VALUE zj_cKeyEvent = rb_const_get(rb_cObject, rb_intern("KeyEvent"));
    VALUE keyEvent = zj_safe_funcall(zj_cKeyEvent, rb_intern("new"), 1, INT2FIX(key));
    if(ruby_error) state = INTERPRETER_ERROR;
    
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, key_up_proc), 1, keyEvent);
    if(ruby_error) state = INTERPRETER_ERROR;
    
    keyIsPressed = false;
  }
}

//--------------------------------------------------------------
// http://www.ruby-forum.com/topic/76498
void ZajalInterpreter::mouseMoved(int x, int y) {
  if(state == INTERPRETER_RUNNING) {
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, mouse_moved_proc), 2, INT2FIX(x), INT2FIX(y));
    if(ruby_error) state = INTERPRETER_ERROR;
  }
}

//--------------------------------------------------------------
void ZajalInterpreter::mouseDragged(int x, int y, int button) {
  if(state == INTERPRETER_RUNNING) {
    lastMouseX = INT2FIX(x);
    lastMouseY = INT2FIX(y);
    lastMouseButton = zj_button_to_symbol(button);

    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, mouse_dragged_proc), 3, lastMouseX, lastMouseY, lastMouseButton);
    if(ruby_error) state = INTERPRETER_ERROR;
  }
}

//--------------------------------------------------------------
void ZajalInterpreter::mousePressed(int x, int y, int button) {
  if(state == INTERPRETER_RUNNING) {
    lastMouseX = INT2FIX(x);
    lastMouseY = INT2FIX(y);
    lastMouseButton = zj_button_to_symbol(button);
    
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, mouse_down_proc), 3, lastMouseX, lastMouseY, lastMouseButton);
    mouseIsPressed = true;
    if(ruby_error) state = INTERPRETER_ERROR;
  }
}


//--------------------------------------------------------------
void ZajalInterpreter::mouseReleased(int x, int y, int button) {
  if(state == INTERPRETER_RUNNING) {
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, mouse_up_proc), 3, INT2FIX(x), INT2FIX(y), zj_button_to_symbol(button));
    if(ruby_error) state = INTERPRETER_ERROR;
    mouseIsPressed = false;
  }
}

//--------------------------------------------------------------
void ZajalInterpreter::windowResized(int w, int h) {
  if(state == INTERPRETER_RUNNING) {
    zj_safe_proc_call(INTERNAL_GET(zj_mEvents, window_resized_proc), 2, INT2FIX(w), INT2FIX(h));
    if(ruby_error) state = INTERPRETER_ERROR;
  }
}

void ZajalInterpreter::initialize() {
  // try and load ZAJAL_PATH environment variable
  char* env_zajal_path = getenv("ZAJAL_PATH");
  if(env_zajal_path) {
    logConsoleText("$stdout", "ZAJAL_PATH from environment: [");
    VALUE zajal_path_ary = rb_str_split(rb_str_new2(env_zajal_path), ":");
    long zajal_path_ary_len = RARRAY_LEN(zajal_path_ary);
    VALUE* zajal_path_ary_ptr = RARRAY_PTR(zajal_path_ary);
    
    for(int i = 0; i < zajal_path_ary_len; i++) {
      rb_ary_push(rb_gv_get("$:"), zajal_path_ary_ptr[i]);
      logConsoleText("$stdout", "'%s', ", StringValuePtr(zajal_path_ary_ptr[i]));
    }
    
    logConsoleText("$stdout", "]\n");
  }
  
  #ifndef EMPTY_LOADPATH
  // only load in defaults if EMPTY_LOADPATH is not set. constants come from
  // config.h
  rb_ary_push(rb_gv_get("$:"), rb_str_new2(ZAJAL_LIBRARY_PATH));
  rb_ary_push(rb_gv_get("$:"), rb_str_new2(ZAJAL_RUBY_STDLIB_PATH));
  #endif
  
  // bail out if no load path was set from environment or command line
  if(RARRAY_LEN(rb_gv_get("$:")) == 0) {
    fprintf(stderr, "FATAL ERROR: No load path set. Zajal cannot run.\n");
    fprintf(stderr, "  Set a load path using the -I option or the $ZAJAL_PATH environment variable\n");
    ::exit(2);
  }
  
  // load in all encodings
  rb_enc_find("encdb");
  
  // require/include useful parts of ruby by default
  rb_include_module(rb_cObject, rb_mMath);
  rb_require("open-uri");
  
  // require ruby-implemented functionality
  rb_require("zajal");
}

void ZajalInterpreter::loadScript(char* fileName) {
  if(scriptName != NULL) free(scriptName);
  scriptName = (char*)calloc(strlen(fileName)+1, sizeof(char));
  strncpy(scriptName, fileName, strlen(fileName)+1);
  
  // try to stat the file, bail out if inaccessible
  struct stat attrib;
  if(stat(scriptName, &attrib)) {
    fprintf(stderr, "FATAL ERROR: Could not access `%s'. Zajal must quit.\n", scriptName);
    fprintf(stderr, "  The file is either missing or otherwise inaccessible. Check the file name\n");
    fprintf(stderr, "  or the file's permissions.\n");
    ::exit(1);
  }
  
  // establish the data path and add it to ruby's load path
  char* scriptNameResolved = realpath(scriptName, NULL);
  VALUE script_directory = rb_str_new2(dirname(scriptNameResolved));
  INTERNAL_SET(zj_mApp, data_path, script_directory);
  rb_ary_unshift(rb_gv_get("$:"), script_directory);
  rb_funcall(rb_gv_get("$:"), rb_intern("uniq!"), 0);

  rb_ary_unshift(INTERNAL_GET(zj_mZajal, watched_files), rb_str_new2(zj_to_data_path(fileName)));
  
  free(scriptNameResolved);
}

void ZajalInterpreter::reloadScript(bool forced, char* filename) {
  // open file, measure size
  if(filename == NULL) filename = scriptName;

  FILE *scriptFile = fopen(filename, "r");
  fseek(scriptFile, 0, SEEK_END);
  long scriptFileSize = ftell(scriptFile);
  fseek(scriptFile, 0, SEEK_SET);
  
  // recovering from an error, force restart
  if(state == INTERPRETER_ERROR)
    forced = true;
  
  if(state == INTERPRETER_RUNNING)
    lastErrorImage.grabScreen(0, 0, ofGetWidth(), ofGetHeight());
  
  logConsoleText("$stdout", "Reading %s (%db)\n", scriptName, (int)scriptFileSize);
  
  // load file into memory
  char* scriptFileContent = (char*)malloc(scriptFileSize * sizeof(char) + 1);
  fread(scriptFileContent, scriptFileSize, 1, scriptFile);
  scriptFileContent[scriptFileSize * sizeof(char)] = '\0';
  fclose(scriptFile);
  
  // neccecity is the mother of all kludges
  if(forced)
    zj_safe_funcall(rb_cObject, rb_intern("live_load"), 2, rb_str_new2(""), Qtrue);
  
  zj_safe_funcall(rb_cObject, rb_intern("live_load"), 2, rb_str_new2(scriptFileContent), forced ? Qtrue : Qfalse);
  state = ruby_error ? INTERPRETER_ERROR : INTERPRETER_RUNNING;
  
  free(scriptFileContent);
}

char* ZajalInterpreter::readConsoleText(char* consoleName, char* prefix, bool clear) {
  VALUE buffer = rb_gv_get(consoleName);
  // TODO prefixing is buggy (creates empty lines in output)
  // rb_funcall(buffer, rb_intern("prefix_lines"), 1, rb_str_new2(prefix));
  
  VALUE buffer_str = rb_funcall(buffer, rb_intern(clear ? "get_buffer!" : "get_buffer"), 0);
  return buffer_str == Qnil ? NULL : RSTRING_PTR(buffer_str);
}

void ZajalInterpreter::writeConsoleText(char* consoleName, char* text) {
  VALUE buffer = rb_gv_get(consoleName);
  rb_funcall(buffer, rb_intern("write"), 1, rb_str_new2(text));
}

void ZajalInterpreter::logConsoleText(char* consoleName, char* format, ...) {
  // TODO sort out how verbosity works
  if(INTERNAL_GET(zj_mApp, verbose) == Qfalse) return;
  
  char buffer[1024];
  va_list args;
  va_start(args, format);
  vsnprintf(buffer, 1024, format, args);
  
  writeConsoleText(consoleName, buffer);
}