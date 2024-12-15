#include <new>
#include "node.h"
#include "jaba.h"

struct JabaNode
{
  Jaba* j;
};

JabaNode* jaba_node_init(Jaba* j)
{
  void* mem = jaba_alloc(j, sizeof(JabaNode));
  JabaNode* n = new(mem) JabaNode;
  n->j = j;
  return n;
}

void jaba_node_term(JabaNode* n)
{
}

void jaba_node_process_attribute(JabaNode* n)
{

}
