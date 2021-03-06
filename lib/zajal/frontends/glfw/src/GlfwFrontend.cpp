#include "GlfwFrontend.h"
#include "GL/glfw.h"

GlfwFrontend::GlfwFrontend() {
  frameCount = 0;
}

void GlfwFrontend::setupOpenGL(int w, int h, int screenMode) {
	glfwInit();
	glfwOpenWindow(w, h, 0, 0, 0, 0, 0, 0, GLFW_WINDOW);
}

int GlfwFrontend::getWidth() {
	return getWindowSize().x;
}

int GlfwFrontend::getHeight() {
	return getWindowSize().y;
}

ofPoint GlfwFrontend::getWindowSize() {
	int w, h;
	glfwGetWindowSize(&w, &h);

	return ofPoint(w, h);
}

void GlfwFrontend::setWindowTitle(string title) {
	glfwSetWindowTitle(title.c_str());
}

void GlfwFrontend::setWindowShape(int w, int h) {
	glfwSetWindowSize(w, h);
}

int GlfwFrontend::getFrameNum() {
  return frameCount;
}

void GlfwFrontend::setFrameNum(int newFrameCount) {
  frameCount = newFrameCount;
}

void GlfwFrontend::incrementFrameNum() {
  frameCount++;
}

void GlfwFrontend::hideCursor() {
  glfwDisable(GLFW_MOUSE_CURSOR);
}

void GlfwFrontend::showCursor() {
  glfwEnable(GLFW_MOUSE_CURSOR);
}
