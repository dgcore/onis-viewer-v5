// Module:  Log4CPLUS
// File:    logger.cxx
// Created: 6/2001
// Author:  Tad E. Smith
//
//
// Copyright 2001-2009 Tad E. Smith
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "dcmtk/oflog/logger.h"
#include "dcmtk/oflog/appender.h"
#include "dcmtk/oflog/helpers/loglog.h"
#include "dcmtk/oflog/hierarchy.h"
#include "dcmtk/oflog/spi/logimpl.h"

namespace log4cplus {

Logger DefaultLoggerFactory::makeNewLoggerInstance(
    const log4cplus::tstring& name, Hierarchy& h) {
  return Logger(new spi::LoggerImpl(name, h));
}

//////////////////////////////////////////////////////////////////////////////
// static Logger Methods
//////////////////////////////////////////////////////////////////////////////
//
Hierarchy& Logger::getDefaultHierarchy() {
  static Hierarchy defaultHierarchy;

  return defaultHierarchy;
}

bool Logger::exists(const log4cplus::tstring& name) {
  return getDefaultHierarchy().exists(name);
}

LoggerList Logger::getCurrentLoggers() {
  return getDefaultHierarchy().getCurrentLoggers();
}

Logger Logger::getInstance(const log4cplus::tstring& name) {
  return getDefaultHierarchy().getInstance(name);
}

Logger Logger::getInstance(const log4cplus::tstring& name,
                           spi::LoggerFactory& factory) {
  return getDefaultHierarchy().getInstance(name, factory);
}

Logger Logger::getRoot() {
  return getDefaultHierarchy().getRoot();
}

void Logger::shutdown() {
  getDefaultHierarchy().shutdown();
}

//////////////////////////////////////////////////////////////////////////////
// Logger ctors and dtor
//////////////////////////////////////////////////////////////////////////////

Logger::Logger() : value(0) {
  int a = 1;
  a = 2;
}

Logger::Logger(spi::LoggerImpl* ptr) : value(ptr) {
  if (value)
    value->addReference();
}

Logger::Logger(const Logger& rhs)
    : spi::AppenderAttachable(rhs), value(rhs.value) {
  if (value)
    value->addReference();
}

Logger& Logger::operator=(const Logger& rhs) {
  Logger(rhs).swap(*this);
  return *this;
}

Logger::~Logger() {
  if (value)
    value->removeReference();
}

//////////////////////////////////////////////////////////////////////////////
// Logger Methods
//////////////////////////////////////////////////////////////////////////////

void Logger::swap(Logger& other) {
  spi::LoggerImpl* tmp = value;
  value = other.value;
  other.value = tmp;
  // STD_NAMESPACE swap (value, other.value);
}

Logger Logger::getParent() const {
  if (value == NULL) {
    int a = 1;
    a = 2;
    return *this;
  }

  if (value->parent)
    return Logger(value->parent.get());
  else {
    value->getLogLog().error(
        LOG4CPLUS_TEXT("********* This logger has no parent: " + getName()));
    return *this;
  }
}

void Logger::addAppender(SharedAppenderPtr newAppender) {
  if (value != NULL) {
    value->addAppender(newAppender);

  } else {
    int a = 1;
    a = 2;
  }
}

SharedAppenderPtrList Logger::getAllAppenders() {
  if (value != NULL)
    return value->getAllAppenders();
  else {
    int a = 1;
    a = 2;
    return value->getAllAppenders();
  }
}

SharedAppenderPtr Logger::getAppender(const log4cplus::tstring& name) {
  if (value != NULL)
    return value->getAppender(name);
  else {
    int a = 1;
    a = 2;
    return SharedAppenderPtr();
  }
}

void Logger::removeAllAppenders() {
  if (value != NULL)
    value->removeAllAppenders();
  else {
    int a = 1;
    a = 2;
  }
}

void Logger::removeAppender(SharedAppenderPtr appender) {
  if (value != NULL)
    value->removeAppender(appender);
  else {
    int a = 1;
    a = 2;
  }
}

void Logger::removeAppender(const log4cplus::tstring& name) {
  if (value != NULL)
    value->removeAppender(name);
  else {
    int a = 1;
    a = 2;
  }
}

void Logger::assertion(bool assertionVal, const log4cplus::tstring& msg) const {
  if (!assertionVal)
    log(FATAL_LOG_LEVEL, msg);
}

void Logger::closeNestedAppenders() const {
  if (value != NULL)
    value->closeNestedAppenders();
  else {
    int a = 1;
    a = 2;
  }
}

bool Logger::isEnabledFor(LogLevel ll) const {
  if (value != NULL)
    return value->isEnabledFor(ll);
  else {
    int a = 1;
    a = 2;
    return false;
  }
}

void Logger::log(LogLevel ll, const log4cplus::tstring& message,
                 const char* file, int line, const char* function) const {
  if (value != NULL)
    value->log(ll, message, file, line, function);
  else {
    int a = 1;
    a = 2;
  }
}

void Logger::forcedLog(LogLevel ll, const log4cplus::tstring& message,
                       const char* file, int line, const char* function) const {
  if (value != NULL)
    value->forcedLog(ll, message, file, line, function);
  else {
    int a = 1;
    a = 2;
  }
}

void Logger::callAppenders(const spi::InternalLoggingEvent& event) const {
  if (value != NULL)
    value->callAppenders(event);
  else {
    int a = 1;
    a = 2;
  }
}

LogLevel Logger::getChainedLogLevel() const {
  if (value != NULL)
    return value->getChainedLogLevel();
  else {
    int a = 1;
    a = 2;
    return value->getChainedLogLevel();
  }
}

LogLevel Logger::getLogLevel() const {
  if (value != NULL)
    return value->getLogLevel();
  else {
    int a = 1;
    a = 2;
    return value->getLogLevel();
  }
}

void Logger::setLogLevel(LogLevel ll) {
  if (value != NULL)
    value->setLogLevel(ll);
  else {
    int a = 1;
    a = 2;
    value->setLogLevel(ll);
  }
}

Hierarchy& Logger::getHierarchy() const {
  if (value != NULL)
    return value->getHierarchy();
  else {
    int a = 1;
    a = 2;
    return value->getHierarchy();
  }
}

log4cplus::tstring Logger::getName() const {
  if (value != NULL)
    return value->getName();
  else {
    int a = 1;
    a = 2;
    return value->getName();
  }
}

bool Logger::getAdditivity() const {
  if (value != NULL)
    return value->getAdditivity();
  else {
    int a = 1;
    a = 2;
    return value->getAdditivity();
  }
}

void Logger::setAdditivity(bool additive) {
  if (value != NULL)
    value->setAdditivity(additive);
  else {
    int a = 1;
    a = 2;
    value->setAdditivity(additive);
  }
}

}  // namespace log4cplus
