import React, { useState } from 'react'
import { colors } from '../../utils/colors'
import { FiPlus, FiMinus, FiHelpCircle } from 'react-icons/fi'

const FAQ = () => {
  const [openFAQ, setOpenFAQ] = useState(null);

  const faqs = [
    {
      id: 1,
      question: "Which languages are supported?",
      answer: "Hindi, English and more regional languages in the roadmap."
    },
    {
      id: 2,
      question: "How is patient data stored?",
      answer: "Secure cloud DB with UHID linking and role-based access; exportable reports."
    },
    {
      id: 3,
      question: "Can it work offline?",
      answer: "Offline-first design planned; core scanning and local storage available in MVP for low connectivity."
    }
  ];

  const toggleFAQ = (id) => {
    setOpenFAQ(openFAQ === id ? null : id);
  };

  return (
    <section 
      className="py-20 px-6" 
      style={{backgroundColor: colors.background}}
    >
      <div className="max-w-4xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-6">
          <div className="flex justify-center">
            <div 
              className="w-16 h-16 rounded-2xl flex items-center justify-center"
              style={{backgroundColor: colors.surfaceSecondary}}
            >
              <FiHelpCircle 
                size={32} 
                style={{color: colors.primary}}
                aria-label="FAQ icon with collapsible answers"
              />
            </div>
          </div>
          
          <h2 
            className="text-4xl md:text-5xl lg:text-6xl font-light leading-tight tracking-tight" 
            style={{color: colors.textPrimary}}
          >
            Frequently asked{' '}
            <span className="font-medium" style={{color: colors.primary}}>questions</span>
          </h2>
        </div>

        {/* FAQ Accordion */}
        <div className="space-y-4">
          {faqs.map((faq) => (
            <div 
              key={faq.id}
              className="rounded-2xl transition-all duration-200"
              style={{
                backgroundColor: colors.surface,
                border: `1px solid ${colors.border}`
              }}
            >
              <button
                className="w-full px-8 py-6 text-left flex items-center justify-between transition-colors duration-200"
                onClick={() => toggleFAQ(faq.id)}
                style={{color: colors.textPrimary}}
              >
                <span className="text-lg font-medium pr-4">
                  {faq.question}
                </span>
                <div 
                  className="w-8 h-8 rounded-full flex items-center justify-center shrink-0 transition-colors duration-200"
                  style={{
                    backgroundColor: openFAQ === faq.id ? colors.primary : colors.surfaceSecondary
                  }}
                >
                  {openFAQ === faq.id ? (
                    <FiMinus 
                      size={16} 
                      style={{color: colors.secondary}}
                    />
                  ) : (
                    <FiPlus 
                      size={16} 
                      style={{color: colors.primary}}
                    />
                  )}
                </div>
              </button>
              
              {openFAQ === faq.id && (
                <div className="px-8 pb-6">
                  <p 
                    className="text-base leading-relaxed font-light" 
                    style={{color: colors.textSecondary}}
                  >
                    {faq.answer}
                  </p>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default FAQ