#pragma once

struct Jaba;
struct JabaNode;

JabaNode* jaba_node_init(Jaba* j);
void jaba_node_term(JabaNode* n);
void jaba_node_process_attribute(JabaNode* n);