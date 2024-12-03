#include <momentum/math/mesh.h>

using namespace momentum;

int main() {
  auto mesh = Mesh();
  mesh.updateNormals();
  return EXIT_SUCCESS;
}
